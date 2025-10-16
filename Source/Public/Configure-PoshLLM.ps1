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
    .PARAMETER Location
        The location can be a URL or an exe name with or without full path
    .PARAMETER ApiKey
        The API key for the LLM system (optional, used for systems that require authentication)
    .PARAMETER ContextSize
        The context size for the LLM (default is 4096, maximum is 65536 bytes / 64KB)
    .EXAMPLE
        Set-PoshLLMConfiguration -LLMSystem "ollama" -Model "llama2" -Location "http://localhost:11434"
    .EXAMPLE
        Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "claude-3.5-sonnet" -Location "claudecode" -ApiKey "your-api-key"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("ollama", "claudecode")]
        [string]$LLMSystem = "ollama",
        
        [Parameter(Mandatory=$false)]
        [string]$Model,
        
        [Parameter(Mandatory=$false)]
        [string]$Location,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 65536)]
        [int]$ContextSize = 4096
    )
    
    # Validate context size does not exceed 64KB (65536 bytes)
    if ($ContextSize -gt 65536) {
        Write-Error "Context size cannot exceed 64KB (65536 bytes). Provided: $ContextSize"
        return
    }
    
    # Create configuration object with only essential fields
    $config = @{
        LLMSystem = $LLMSystem
        ContextSize = $ContextSize
    }
    
    # Add Location - set default based on LLM system if not provided
    if ($PSBoundParameters.ContainsKey('Location')) {
        $config.Location = $Location
    } else {
        # Set default location based on LLM system
        if ($LLMSystem -eq "claudecode") {
            $config.Location = "claude"
        } else {
            $config.Location = "http://localhost:11434"
        }
    }
    
    # Add Model only if explicitly provided (if not provided, system will use its default)
    if ($PSBoundParameters.ContainsKey('Model') -and -not [string]::IsNullOrEmpty($Model)) {
        $config.Model = $Model
    }
    
    # Add ApiKey only if explicitly provided
    if ($PSBoundParameters.ContainsKey('ApiKey') -and -not [string]::IsNullOrEmpty($ApiKey)) {
        $config.ApiKey = $ApiKey
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
    if ($PSBoundParameters.ContainsKey('Model') -and -not [string]::IsNullOrEmpty($Model)) {
        Write-Host "Model: $Model" -ForegroundColor Yellow
    } else {
        Write-Host "Model: (using system default)" -ForegroundColor Yellow
    }
    Write-Host "Location: $($config.Location)" -ForegroundColor Yellow
    if ($PSBoundParameters.ContainsKey('ApiKey')) {
        Write-Host "API Key: ***configured***" -ForegroundColor Yellow
    }
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
