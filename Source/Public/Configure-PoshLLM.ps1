function Set-PoshLLMConfiguration {
    <#
    .SYNOPSIS
        Configures the PoshLLM module with LLM connection details
    .DESCRIPTION
        Sets up the connection parameters for the LLM system to be used by PoshLLM
    .PARAMETER LLMSystem
        The name of the LLM system (e.g., ollama)
    .PARAMETER Model
        The model to use for requests
    .PARAMETER URL
        The URL for the LLM system
    .PARAMETER ContextSize
        The context size for the LLM (default is 4096, maximum is 65536 bytes / 64KB)
    .EXAMPLE
        Set-PoshLLMConfiguration -LLMSystem "ollama" -Model "llama2" -URL "http://localhost:11434"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("ollama")]
        [string]$LLMSystem = "ollama",
        
        [Parameter(Mandatory=$false)]
        [string]$Model = "qwen3:8b",
        
        [Parameter(Mandatory=$false)]
        [string]$URL = "http://localhost:11434",
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 65536)]
        [int]$ContextSize = 4096
    )
    
    # Validate context size does not exceed 64KB (65536 bytes)
    if ($ContextSize -gt 65536) {
        Write-Error "Context size cannot exceed 64KB (65536 bytes). Provided: $ContextSize"
        return
    }
    
    # Create configuration object
    $config = @{
        LLMSystem = $LLMSystem
        Model = $Model
        URL = $URL
        ContextSize = $ContextSize
    }
    
    # Save configuration to a file
    $configPath = "$env:APPDATA\PoshLLM\config.json"
    $configDirectory = Split-Path $configPath -Parent
    
    if (-not (Test-Path $configDirectory)) {
        New-Item -Path $configDirectory -ItemType Directory -Force
    }
    
    $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding UTF8
    
    Write-Host "PoshLLM configured successfully!" -ForegroundColor Green
    Write-Host "LLM System: $LLMSystem" -ForegroundColor Yellow
    Write-Host "Model: $Model" -ForegroundColor Yellow
    Write-Host "URL: $URL" -ForegroundColor Yellow
    Write-Host "Context Size: $ContextSize" -ForegroundColor Yellow
}

function Get-PoshLLMConfig {
    <#
    .SYNOPSIS
        Gets the current PoshLLM configuration
    .DESCRIPTION
        Retrieves the saved configuration for the LLM system
    .EXAMPLE
        Get-PoshLLMConfig
    #>
    [CmdletBinding()]
    param()
    
    $configPath = "$env:APPDATA\PoshLLM\config.json"
    
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath | ConvertFrom-Json
            # Convert PSCustomObject to Hashtable for compatibility
            $hashtableConfig = @{}
            $config | Get-Member -MemberType NoteProperty | ForEach-Object {
                $hashtableConfig[$_.Name] = $config.$($_.Name)
            }
            return $hashtableConfig
        }
        catch {
            Write-Error "Failed to read configuration: $($_.Exception.Message)"
            return $null
        }
    }
    else {
        return $null
    }
}

# Create alias for backward compatibility
Set-Alias -Name Configure-PoshLLM -Value Set-PoshLLMConfiguration
