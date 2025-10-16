function Invoke-LLM {
    <#
    .SYNOPSIS
        Sends input to an LLM and processes the response
    .DESCRIPTION
        Takes any input and sends it to an LLM system. If the LLM returns information,
        it is displayed. If it returns code, the user is prompted to execute it, 
        put it in the clipboard, or exit.
    .PARAMETER Prompt
        The input to send to the LLM
    .PARAMETER LLMSystem
        Override the configured LLM system
    .PARAMETER Model
        Override the configured model
    .PARAMETER URL
        Override the configured URL
    .PARAMETER ContextSize
        Override the configured context size (maximum 65536 bytes / 64KB)
    .PARAMETER ResponseType
        Override the response type (Text, Data, Script)
    .PARAMETER DataFormat
        Override the data format when ResponseType is Data (JSON, CSV, XML)
    .PARAMETER IncludeContext
        Include the last N lines of console output as context for the LLM
    .PARAMETER Raw
        Return the raw LLM response without any formatting or prompts. Useful for script automation.
    .PARAMETER GetPrompt
        Return the enhanced prompt that would be sent to the LLM without actually sending it. Useful for debugging and understanding what context is being provided to the LLM.
    .EXAMPLE
        Invoke-LLM "What is PowerShell?"
    .EXAMPLE
        Invoke-LLM -Prompt "Write a function to list files" -Model "llama3:latest"
    .EXAMPLE
        ai "What is PowerShell?"  # Using the 'ai' alias
    .EXAMPLE
        llm "list running processes"  # Using the 'llm' alias
    .EXAMPLE
        ai "list 10 boy names" -ResponseType Data -DataFormat CSV
    .EXAMPLE
        ask "get running processes" -ResponseType Script
    .EXAMPLE
        ai "what does this error mean?" -IncludeContext 20
    .EXAMPLE
        $code = ai "Create a function Get-LargeFiles that finds files over 100MB" -Raw
    .EXAMPLE
        $prompt = ai "list files" -IncludeContext 5 -GetPrompt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$false)]
        [string]$LLMSystem,
        
        [Parameter(Mandatory=$false)]
        [string]$Model,
        
        [Parameter(Mandatory=$false)]
        [string]$URL,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 65536)]
        [int]$ContextSize,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Text', 'Data', 'Script')]
        [string]$ResponseType,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('JSON', 'CSV', 'XML')]
        [string]$DataFormat,
        
        [Parameter(Mandatory=$false)]
        [int]$IncludeContext = 0,
        
        [Parameter(Mandatory=$false)]
        [switch]$Raw,
        
        [Parameter(Mandatory=$false)]
        [switch]$GetPrompt
    )
    
    # Get the current configuration
    $configObj = Get-PoshLLMConfig
    
    if (-not $configObj) {
        Write-Error "No configuration found. Please run Configure-PoshLLM first."
        return
    }
    
    # Create a new hashtable from config
    $config = @{
        LLMSystem = $configObj.LLMSystem
        Model = $configObj.Model
        URL = $configObj.URL
        ContextSize = $configObj.ContextSize
    }
    
    # Override config values if parameters are provided
    if ($PSBoundParameters.ContainsKey('LLMSystem')) {
        $config.LLMSystem = $LLMSystem
    }
    if ($PSBoundParameters.ContainsKey('Model')) {
        $config.Model = $Model
    }
    if ($PSBoundParameters.ContainsKey('URL')) {
        $config.URL = $URL
    }
    if ($PSBoundParameters.ContainsKey('ContextSize')) {
        # Validate context size does not exceed 64KB (65536 bytes)
        if ($ContextSize -gt 65536) {
            Write-Error "Context size cannot exceed 64KB (65536 bytes). Provided: $ContextSize"
            return
        }
        $config.ContextSize = $ContextSize
    }
    
    # Gather system information
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $osVersion = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        [System.Environment]::OSVersion.VersionString
    } elseif ($IsLinux) {
        "Linux"
    } elseif ($IsMacOS) {
        "macOS"
    } else {
        "Unknown OS"
    }
    
    # Capture console history if requested
    $consoleContext = ""
    if ($IncludeContext -gt 0) {
        try {
            $history = Get-History -Count $IncludeContext -ErrorAction SilentlyContinue
            if ($history) {
                $consoleContext = "`n`nRecent Console Output Context (last $IncludeContext commands):`n"
                $consoleContext += "``````powershell`n"
                foreach ($item in $history) {
                    $consoleContext += "PS> $($item.CommandLine)`n"
                }
                $consoleContext += "``````"
            }
        }
        catch {
            # Silently ignore if history capture fails
        }
    }
    
    # Build enhanced prompt with context
    $formatInstructions = ""
    
    # Override format instructions based on parameters
    if ($PSBoundParameters.ContainsKey('ResponseType')) {
        switch ($ResponseType) {
            'Text' {
                $formatInstructions = 'Respond in clear TEXT format providing information or answering the question.'
            }
            'Data' {
                if ($PSBoundParameters.ContainsKey('DataFormat')) {
                    $df = $DataFormat
                    $formatInstructions = "Respond with the data in $df format. Provide ONLY the data without any additional explanation or wrapping."
                } else {
                    $formatInstructions = 'Respond with the data in JSON format. Provide ONLY the JSON data without any additional explanation or wrapping.'
                }
            }
            'Script' {
                $formatInstructions = "Respond with a PowerShell script compatible with PowerShell version $psVersion and OS: $osVersion. Wrap the script in a code block using triple backticks."
            }
        }
    } else {
        # Default auto-detection instructions
        $nl = [Environment]::NewLine
        $psv = $psVersion
        $osv = $osVersion
        $formatInstructions = 'If this is a REQUEST FOR INFORMATION or an ANSWER to a question: Respond in clear TEXT format.'
        $formatInstructions += $nl + 'If this is a REQUEST FOR DATA: Respond in the format explicitly requested by the user (CSV, JSON, XML, etc.). If no specific format is mentioned, use JSON format.'
        $formatInstructions += $nl + "If this is a REQUEST TO ACCOMPLISH A TASK or execute an action (especially involving system-level operations like listing processes, checking ports, managing files, registry operations, services, network connections, or any system administration task): Respond with the correct PowerShell script compatible with PowerShell version $psv and OS: $osv. Wrap the script in a code block using triple backticks."
    }
    
    # Build the enhanced prompt
    $enhancedPrompt = "System Context:"
    $enhancedPrompt += "`n- PowerShell Version: $psVersion"
    $enhancedPrompt += "`n- Operating System: $osVersion"
    $enhancedPrompt += $consoleContext
    $enhancedPrompt += "`n`nInstructions for Response Format:"
    $enhancedPrompt += "`n$formatInstructions"
    $enhancedPrompt += "`n`nUser Request:"
    $enhancedPrompt += "`n$Prompt"
    
    # If GetPrompt switch is specified, return the enhanced prompt without sending it
    if ($GetPrompt) {
        return $enhancedPrompt
    }
    
    # Validate enhanced prompt size does not exceed 64KB
    $promptSizeBytes = [System.Text.Encoding]::UTF8.GetByteCount($enhancedPrompt)
    if ($promptSizeBytes -gt 65536) {
        Write-Error "Enhanced prompt size ($promptSizeBytes bytes) exceeds the maximum allowed size of 64KB (65536 bytes). Consider reducing the prompt or context."
        return
    }
    
    # Send enhanced input to the configured LLM system
    $response = Send-ToLLM -InputText $enhancedPrompt -Config $config
    
    if ($response) {
        # If Raw switch is specified, return just the response without formatting
        if ($Raw) {
            return $response
        }
        
        # Determine if we should check for code blocks based on ResponseType
        $shouldCheckForCode = $true
        if ($PSBoundParameters.ContainsKey('ResponseType')) {
            # If ResponseType is explicitly set to Text or Data, don't check for code
            if ($ResponseType -eq 'Text' -or $ResponseType -eq 'Data') {
                $shouldCheckForCode = $false
            }
        }
        
        # Check if the response contains code (only if appropriate)
        if ($shouldCheckForCode -and ($response -match '(?s)```(?:\w+)?\s*(.*?)```')) {
            # Extract the code block
            $codeBlock = $matches[1]
            
            Write-Host "LLM Response contains code:" -ForegroundColor Yellow
            Write-Host ""
            
            # Display the code with syntax highlighting
            Show-SyntaxHighlightedCode -Code $codeBlock
            Write-Host ""
            
            # Prompt user for action
            $choice = Show-CodeActionPrompt -Code $codeBlock
            switch ($choice) {
                1 { 
                    # Execute the code
                    try {
                        Invoke-Expression $codeBlock
                        Write-Host "Code executed successfully." -ForegroundColor Green
                    }
                    catch {
                        Write-Error "Failed to execute code: $($_.Exception.Message)"
                    }
                }
                2 { 
                    # Copy to clipboard
                    Add-Content -Path $env:TEMP\PoshLLM_Code.txt -Value $codeBlock
                    Set-Clipboard -Value $codeBlock
                    Write-Host "Code copied to clipboard." -ForegroundColor Green
                }
                3 { 
                    # Exit
                    Write-Host "Exiting without executing code." -ForegroundColor Yellow
                }
            }
        }
        else {
            # Display regular text response
            Write-Host "LLM Response:" -ForegroundColor Green
            Write-Host $response -ForegroundColor Cyan
        }
    }
    else {
        Write-Warning "No response received from LLM."
    }
}

# Create convenient short aliases for Invoke-LLM
Set-Alias -Name ai -Value Invoke-LLM
Set-Alias -Name llm -Value Invoke-LLM
Set-Alias -Name ask -Value Invoke-LLM

function Send-ToLLM {
    <#
    .SYNOPSIS
        Internal method to send input to LLM system
    .DESCRIPTION
        Abstracts the connection to different LLM systems. Currently implements Ollama.
    .PARAMETER InputText
        The input to send to the LLM
    .PARAMETER Config
        Configuration object containing LLM connection details
    .EXAMPLE
        Send-ToLLM -InputText "Hello" -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputText,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    # Check which LLM system is configured
    switch ($Config.LLMSystem) {
        "ollama" {
            return Send-ToOllama -InputText $InputText -Config $Config
        }
        default {
            Write-Error "Unsupported LLM system: $($Config.LLMSystem)"
            return $null
        }
    }
}

function Send-ToOllama {
    <#
    .SYNOPSIS
        Sends input to Ollama LLM system via API
    .DESCRIPTION
        Connects to Ollama API and sends the input for processing
    .PARAMETER InputText
        The input to send to Ollama
    .PARAMETER Config
        Configuration object containing Ollama connection details
    .EXAMPLE
        Send-ToOllama -InputText "Hello" -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputText,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    try {
        # Build the request body
        $body = @{
            model = $Config.Model
            prompt = $InputText
            stream = $false
        } | ConvertTo-Json
        
        # Send request to Ollama
        $baseUrl = $Config.URL
        $apiPath = '/api/generate'
        $uri = $baseUrl + $apiPath
        $contentType = 'application/json'
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType $contentType
        
        return $response.response
    }
    catch {
        Write-Error 'Failed to connect to Ollama. Please check your connection and configuration.'
        return $null
    }
}

function Show-CodeActionPrompt {
    <#
    .SYNOPSIS
        Prompts user for action when LLM response contains code
    .DESCRIPTION
        Displays options for handling code returned by LLM
    .PARAMETER Code
        The code block to process
    .EXAMPLE
        Show-CodeActionPrompt -Code "Get-Process"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code
    )
    
    Write-Host ""
    do {
        $choice = Read-Host "[C]opy to clipboard (default), [E]xecute, or E[x]it"
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $choice = "C"
        }
        $choice = $choice.ToUpper()
    } while ($choice -notmatch '^[CEX]$')
    
    # Convert letter to number for backward compatibility with switch statement
    switch ($choice) {
        "E" { return 1 }
        "C" { return 2 }
        "X" { return 3 }
    }
}
