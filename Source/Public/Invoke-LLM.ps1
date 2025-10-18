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
    .PARAMETER Config
        Configuration hashtable containing any of the following keys:
        - LLMSystem: The LLM system to use (e.g., 'ollama', 'claudecode')
        - Model: The model to use
        - Location: The location (URL or exe path)
        - ContextSize: The context size (maximum 65536 bytes / 64KB)
        - ApiKey: The API key (if required)
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
        Invoke-LLM -Prompt "Write a function to list files" -Config @{Model = "llama3:latest"}
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
        [hashtable]$Config,
        
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
    
    if (-not $configObj -and -not $PSBoundParameters.ContainsKey('Config')) {
        Write-Error "No configuration found. Please run Configure-PoshLLM first or provide a Config parameter."
        return
    }
    
    # Start with saved config (if it exists)
    $finalConfig = @{}
    if ($configObj) {
        foreach ($key in $configObj.Keys) {
            $finalConfig[$key] = $configObj[$key]
        }
    }
    
    # Override with provided Config parameter if present
    if ($PSBoundParameters.ContainsKey('Config')) {
        foreach ($key in $Config.Keys) {
            # Validate ContextSize if provided
            if ($key -eq 'ContextSize' -and $Config[$key] -gt 65536) {
                Write-Error "Context size cannot exceed 64KB (65536 bytes). Provided: $($Config[$key])"
                return
            }
            $finalConfig[$key] = $Config[$key]
        }
    }
    
    # Validate that we have the minimum required configuration
    if (-not $finalConfig.ContainsKey('LLMSystem') -or [string]::IsNullOrEmpty($finalConfig.LLMSystem)) {
        Write-Error "LLMSystem is required in configuration."
        return
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
                    $formatInstructions = "Respond with the data in $DataFormat format. Provide ONLY the data without any additional explanation or wrapping."
                } else {
                    $formatInstructions = 'Respond with the data in JSON format. Provide ONLY the JSON data without any additional explanation or wrapping.'
                }
            }
            'Script' {
                $formatInstructions = "Respond with a PowerShell script compatible with PowerShell version $psVersion and OS: $osVersion. Wrap the script in a code block using triple backticks.`n`nIMPORTANT: Ensure all PowerShell commands use valid cmdlet names, valid parameter names, and valid parameter values. Verify that:`n- All cmdlet names exist in PowerShell $psVersion`n- All parameter names are valid for the cmdlets being used`n- All parameter values match the expected types (string, int, bool, arrays, hashtables, etc.)`n- Parameter names start with '-' when calling cmdlets`n- String values are properly quoted when containing spaces or special characters`n- Boolean parameters use `$true/`$false or are specified as switches`n- Paths use PowerShell-compatible formats`n- Enum values match valid enumeration values for the parameter`n- When a grave mark (```) appears in double quotes, escape it as double grave (````````) `n- When using string interpolation with variables followed by special characters (like colons), wrap the variable in `$() syntax: e.g., `"`$(`$name): `$value`" instead of `"`$name: `$value`""
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
        $formatInstructions += $nl + $nl + "IMPORTANT for PowerShell scripts: Ensure all PowerShell commands use valid cmdlet names, valid parameter names, and valid parameter values. Verify that:"
        $formatInstructions += $nl + "- All cmdlet names exist in PowerShell $psv"
        $formatInstructions += $nl + "- All parameter names are valid for the cmdlets being used"
        $formatInstructions += $nl + "- All parameter values match the expected types (string, int, bool, arrays, hashtables, etc.)"
        $formatInstructions += $nl + "- Parameter names start with '-' when calling cmdlets"
        $formatInstructions += $nl + "- String values are properly quoted when containing spaces or special characters"
        $formatInstructions += $nl + "- Boolean parameters use `$true/`$false or are specified as switches"
        $formatInstructions += $nl + "- Paths use PowerShell-compatible formats"
        $formatInstructions += $nl + "- Enum values match valid enumeration values for the parameter"
        $formatInstructions += $nl + "- When a grave mark (`) appears in double quotes, escape it as double grave (``) "
        $formatInstructions += $nl + "- When using string interpolation with variables followed by special characters (like colons), wrap the variable in `$() syntax: e.g., `"`$(`$name): `$value`" instead of `"`$name: `$value`""
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
    $response = Send-ToLLM -InputText $enhancedPrompt -Config $finalConfig
    
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
            
            # Track alternate suggestions to avoid repeats
            $alternateHistory = @()
            $continuePrompting = $true
            
            while ($continuePrompting) {
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
                            $continuePrompting = $false
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
                        $continuePrompting = $false
                    }
                    3 { 
                        # Exit
                        Write-Host "Exiting without executing code." -ForegroundColor Yellow
                        $continuePrompting = $false
                    }
                    4 {
                        # Fix - Ask LLM to clean up the suggestion
                        Write-Host "Requesting LLM to fix the suggestion..." -ForegroundColor Yellow
                        
                        $fixPrompt = "There seems to be an issue with the following PowerShell script suggestion. Please review it and provide a corrected version that addresses any potential issues:`n`n``````powershell`n$codeBlock`n```````n`nPlease provide the fixed script wrapped in a code block."
                        
                        $fixResponse = Send-ToLLM -InputText $fixPrompt -Config $finalConfig
                        
                        if ($fixResponse -and ($fixResponse -match '(?s)```(?:\w+)?\s*(.*?)```')) {
                            $codeBlock = $matches[1]
                            Write-Host ""
                        }
                        else {
                            Write-Warning "No valid code block received from LLM fix attempt."
                            $continuePrompting = $false
                        }
                    }
                    5 {
                        # Alternate - Ask LLM for a different solution
                        Write-Host "Requesting an alternate solution from LLM..." -ForegroundColor Yellow
                        
                        # Add current suggestion to history
                        $alternateHistory += $codeBlock
                        
                        # Build prompt with history of previous suggestions
                        $alternatePrompt = "Please provide an ALTERNATE solution to this request:`n`n$Prompt`n`n"
                        $alternatePrompt += "The following solution(s) have already been suggested. Please provide a DIFFERENT approach:`n`n"
                        
                        for ($i = 0; $i -lt $alternateHistory.Count; $i++) {
                            $alternatePrompt += "Solution $($i + 1):`n``````powershell`n$($alternateHistory[$i])`n```````n`n"
                        }
                        
                        $alternatePrompt += "Please provide an alternate PowerShell script solution wrapped in a code block."
                        
                        $alternateResponse = Send-ToLLM -InputText $alternatePrompt -Config $finalConfig
                        
                        if ($alternateResponse -and ($alternateResponse -match '(?s)```(?:\w+)?\s*(.*?)```')) {
                            $codeBlock = $matches[1]
                            Write-Host ""
                        }
                        else {
                            Write-Warning "No valid code block received from LLM alternate attempt."
                            $continuePrompting = $false
                        }
                    }
                    6 {
                        # Redirect - User provides custom prompt with the suggested script in context
                        Write-Host ""
                        $redirectInput = Read-Host "Enter your redirect prompt (what would you like the LLM to do with this script?)"
                        
                        if (-not [string]::IsNullOrWhiteSpace($redirectInput)) {
                            Write-Host "Sending redirect request to LLM..." -ForegroundColor Yellow
                            
                            $redirectPrompt = "$redirectInput`n`nContext - Current suggested script:`n``````powershell`n$codeBlock`n```````n`nPlease respond to the request above."
                            
                            $redirectResponse = Send-ToLLM -InputText $redirectPrompt -Config $finalConfig
                            
                            if ($redirectResponse -and ($redirectResponse -match '(?s)```(?:\w+)?\s*(.*?)```')) {
                                $codeBlock = $matches[1]
                                Write-Host ""
                            }
                            else {
                                # No code block in response, display as text
                                Write-Host "LLM Response:" -ForegroundColor Green
                                Write-Host $redirectResponse -ForegroundColor Cyan
                                $continuePrompting = $false
                            }
                        }
                        else {
                            Write-Warning "No redirect prompt provided."
                            $continuePrompting = $false
                        }
                    }
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
        "claudecode" {
            return Send-ToClaudeCode -InputText $InputText -Config $Config
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
        # Use default URL if location is empty
        $baseUrl = if ($Config.ContainsKey('Location') -and -not [string]::IsNullOrEmpty($Config.Location)) {
            $Config.Location
        } else {
            'http://localhost:11434'
        }
        
        # Determine which model to use
        $modelToUse = $null
        if ($Config.ContainsKey('Model') -and -not [string]::IsNullOrEmpty($Config.Model)) {
            $modelToUse = $Config.Model
        } else {
            # No model specified, fetch the most recently used model from Ollama
            try {
                $tagsUri = $baseUrl + '/api/tags'
                $tagsResponse = Invoke-RestMethod -Uri $tagsUri -Method Get -ErrorAction Stop
                
                if ($tagsResponse.models -and $tagsResponse.models.Count -gt 0) {
                    # Sort by modified_at (most recent first) and take the first one
                    $mostRecentModel = $tagsResponse.models | Sort-Object { [DateTime]$_.modified_at } -Descending | Select-Object -First 1
                    $modelToUse = $mostRecentModel.name
                    Write-Verbose "No model specified, using most recently used model: $modelToUse"
                } else {
                    Write-Error "No model specified and no models found in Ollama. Please specify a model or install one in Ollama."
                    return $null
                }
            } catch {
                Write-Error "Failed to fetch available models from Ollama: $($_.Exception.Message)"
                return $null
            }
        }
        
        # Build the request body
        $body = @{
            prompt = $InputText
            stream = $false
            model = $modelToUse
        }
        
        $body = $body | ConvertTo-Json
        
        # Send request to Ollama
        $apiPath = '/api/generate'
        $uri = $baseUrl + $apiPath
        $contentType = 'application/json'
        
        # Prepare headers
        $headers = @{
            'Content-Type' = $contentType
        }
        
        # Add bearer token if API key is present
        if ($Config.ContainsKey('ApiKey') -and -not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $headers['Authorization'] = "Bearer $($Config.ApiKey)"
        }
        
        # Make the request
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers
        
        return $response.response
    }
    catch {
        Write-Error 'Failed to connect to Ollama. Please check your connection and configuration.'
        return $null
    }
}

function Send-ToClaudeCode {
    <#
    .SYNOPSIS
        Sends input to ClaudeCode CLI tool
    .DESCRIPTION
        Connects to ClaudeCode CLI (claude.exe) and sends the input for processing via stdin
    .PARAMETER InputText
        The input to send to ClaudeCode
    .PARAMETER Config
        Configuration object containing ClaudeCode connection details
    .EXAMPLE
        Send-ToClaudeCode -InputText "Hello" -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputText,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    try {
        # Use the configured location (exe path) or default to "claude"
        $claudeExe = if ($Config.ContainsKey('Location') -and -not [string]::IsNullOrEmpty($Config.Location)) {
            $Config.Location
        } else {
            "claude"
        }
        
        # Build arguments array for non-interactive mode
        $arguments = @(
            '--print'
            '--output-format'
            'text'
        )
        
        # Add model if specified
        if ($Config.ContainsKey('Model') -and -not [string]::IsNullOrEmpty($Config.Model)) {
            $arguments += '--model'
            $arguments += $Config.Model
        }
        
        # Use pipeline to send InputText to claude via stdin
        # This handles multi-line prompts and special characters better
        $response = $InputText | & $claudeExe @arguments 2>&1
        
        # Convert response to string if it's an array
        if ($response -is [array]) {
            $response = $response -join "`n"
        }
        
        return $response
    }
    catch {
        Write-Error "Failed to connect to ClaudeCode CLI. Please check that 'claude' is installed and in your PATH. Error: $($_.Exception.Message)"
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
        $choice = Read-Host "[C]opy to clipboard (default), [E]xecute, [F]ix, [A]lternate, [R]edirect, or E[x]it"
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $choice = "C"
        }
        $choice = $choice.ToUpper()
    } while ($choice -notmatch '^[CEFARX]$')
    
    # Convert letter to number for backward compatibility with switch statement
    switch ($choice) {
        "E" { return 1 }
        "C" { return 2 }
        "X" { return 3 }
        "F" { return 4 }
        "A" { return 5 }
        "R" { return 6 }
    }
}
