<#
.SYNOPSIS
    Publishes the PoshLLM module to PowerShell Gallery

.DESCRIPTION
    This script publishes the PoshLLM module to the PowerShell Gallery.
    It requires a valid API key from PowerShell Gallery.

.PARAMETER ApiKey
    PowerShell Gallery API key (required)

.PARAMETER BuildPath
    Path to the build directory (default: ./build)

.PARAMETER Repository
    Target repository name (default: PSGallery)

.PARAMETER WhatIf
    Show what would be published without actually publishing

.EXAMPLE
    .\publish.ps1 -ApiKey "your-api-key-here"
    
.EXAMPLE
    .\publish.ps1 -ApiKey "your-api-key-here" -WhatIf
    
.EXAMPLE
    .\publish.ps1 -ApiKey "your-api-key-here" -BuildPath "C:\Builds\PoshLLM"

.NOTES
    You can get your API key from: https://www.powershellgallery.com/account/apikeys
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$BuildPath = "./build",
    
    [Parameter(Mandatory=$false)]
    [string]$Repository = "PSGallery",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host "PoshLLM Publish Script" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# Validate API key
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Error "API key is required. Get your key from https://www.powershellgallery.com/account/apikeys"
    exit 1
}

# Check if build directory exists
$modulePath = Join-Path $BuildPath "PoshLLM"
if (-not (Test-Path $modulePath)) {
    Write-Error "Build directory not found at $modulePath. Run .\build.ps1 first."
    exit 1
}

# Get module manifest
$manifestPath = Join-Path $modulePath "PoshLLM.psd1"
if (-not (Test-Path $manifestPath)) {
    Write-Error "Module manifest not found at $manifestPath"
    exit 1
}

# Import manifest to get details
$manifest = Import-PowerShellDataFile -Path $manifestPath
$moduleName = "PoshLLM"
$moduleVersion = $manifest.ModuleVersion

Write-Host "Publishing: $moduleName v$moduleVersion" -ForegroundColor Yellow
Write-Host "Repository: $Repository" -ForegroundColor Yellow
Write-Host ""

# Validate the module one more time
Write-Host "Validating module manifest..." -ForegroundColor Green
try {
    $moduleInfo = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-Host "✓ Module manifest is valid" -ForegroundColor Green
} catch {
    Write-Error "Module manifest validation failed: $($_.Exception.Message)"
    exit 1
}

# Display module information
Write-Host ""
Write-Host "Module Information" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Name:        $($moduleInfo.Name)" -ForegroundColor White
Write-Host "Version:     $($moduleInfo.Version)" -ForegroundColor White
Write-Host "Author:      $($moduleInfo.Author)" -ForegroundColor White
Write-Host "Description: $($moduleInfo.Description)" -ForegroundColor White
Write-Host "Functions:   $($moduleInfo.ExportedFunctions.Count) exported" -ForegroundColor White
Write-Host "Aliases:     $($moduleInfo.ExportedAliases.Count) exported" -ForegroundColor White
Write-Host ""

# Check if module already exists in repository
Write-Host "Checking if module version already exists..." -ForegroundColor Green
try {
    $existingModule = Find-Module -Name $moduleName -Repository $Repository -ErrorAction SilentlyContinue
    if ($existingModule -and $existingModule.Version -eq $moduleVersion) {
        Write-Warning "Version $moduleVersion already exists in $Repository!"
        $continue = Read-Host "Do you want to continue anyway? (y/N)"
        if ($continue -ne 'y') {
            Write-Host "Publish cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    # Module not found or error checking - continue
    Write-Host "✓ Version check complete" -ForegroundColor Green
}

# Confirm publication
if (-not $WhatIf) {
    Write-Host ""
    Write-Host "WARNING: You are about to publish to $Repository" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Host "Publish cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Publish the module
Write-Host ""
Write-Host "Publishing module..." -ForegroundColor Green

try {
    $publishParams = @{
        Path = $modulePath
        NuGetApiKey = $ApiKey
        Repository = $Repository
        Verbose = $true
        Force = $true
    }
    
    if ($WhatIf) {
        Write-Host "WhatIf: Would publish module with the following parameters:" -ForegroundColor Yellow
        $publishParams | ConvertTo-Json | Write-Host
    } else {
        Publish-Module @publishParams
        
        Write-Host ""
        Write-Host "Module published successfully! ✓" -ForegroundColor Green
        Write-Host ""
        Write-Host "Module is now available at:" -ForegroundColor Cyan
        Write-Host "https://www.powershellgallery.com/packages/$moduleName/$moduleVersion" -ForegroundColor White
        Write-Host ""
        Write-Host "Users can install it with:" -ForegroundColor Cyan
        Write-Host "Install-Module -Name $moduleName" -ForegroundColor White
        Write-Host ""
    }
} catch {
    Write-Error "Failed to publish module: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "- Invalid API key" -ForegroundColor Yellow
    Write-Host "- Version already exists (increment version in PoshLLM.psd1)" -ForegroundColor Yellow
    Write-Host "- Network connectivity issues" -ForegroundColor Yellow
    Write-Host "- Module manifest validation errors" -ForegroundColor Yellow
    exit 1
}
