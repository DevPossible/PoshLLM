<#
.SYNOPSIS
    Builds the PoshLLM module package for publishing

.DESCRIPTION
    This script prepares the PoshLLM module for publishing to PowerShell Gallery.
    It validates the module, runs tests, and creates a distribution package.

.PARAMETER SkipTests
    Skip running tests before building

.PARAMETER OutputPath
    Path where the build output should be placed (default: ./build)

.EXAMPLE
    .\build.ps1
    
.EXAMPLE
    .\build.ps1 -SkipTests
    
.EXAMPLE
    .\build.ps1 -OutputPath "C:\Builds\PoshLLM"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./build"
)

Write-Host "PoshLLM Build Script" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

# Get module manifest
$manifestPath = "./PoshLLM.psd1"
if (-not (Test-Path $manifestPath)) {
    Write-Error "Module manifest not found at $manifestPath"
    exit 1
}

# Import the manifest
$manifest = Import-PowerShellDataFile -Path $manifestPath
$moduleName = "PoshLLM"
$moduleVersion = $manifest.ModuleVersion

Write-Host "Building: $moduleName v$moduleVersion" -ForegroundColor Yellow
Write-Host ""

# Run tests unless skipped
if (-not $SkipTests) {
    Write-Host "Running tests..." -ForegroundColor Green
    & "./test.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed. Build aborted."
        exit 1
    }
    Write-Host ""
}

# Create output directory
Write-Host "Creating build directory..." -ForegroundColor Green
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

$modulePath = Join-Path $OutputPath $moduleName

# Create module directory structure
Write-Host "Creating module structure..." -ForegroundColor Green
New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
New-Item -Path "$modulePath/Source" -ItemType Directory -Force | Out-Null
New-Item -Path "$modulePath/Source/Public" -ItemType Directory -Force | Out-Null
New-Item -Path "$modulePath/Source/Private" -ItemType Directory -Force | Out-Null

# Copy module files
Write-Host "Copying module files..." -ForegroundColor Green
Copy-Item -Path "./PoshLLM.psd1" -Destination "$modulePath/" -Force
Copy-Item -Path "./LICENSE" -Destination "$modulePath/" -Force
Copy-Item -Path "./README.md" -Destination "$modulePath/" -Force

# Copy source files
Copy-Item -Path "./Source/PoshLLM.psm1" -Destination "$modulePath/Source/" -Force
Copy-Item -Path "./Source/Public/*.ps1" -Destination "$modulePath/Source/Public/" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "./Source/Private/*.ps1" -Destination "$modulePath/Source/Private/" -Force -ErrorAction SilentlyContinue

# Validate the module
Write-Host "Validating module..." -ForegroundColor Green
$testModulePath = Join-Path $modulePath "PoshLLM.psd1"
try {
    Test-ModuleManifest -Path $testModulePath -ErrorAction Stop | Out-Null
    Write-Host "Module manifest is valid!" -ForegroundColor Green
} catch {
    Write-Error "Module manifest validation failed: $($_.Exception.Message)"
    exit 1
}

# Create version info file
$buildInfo = @{
    Version = $moduleVersion
    BuildDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
}
$buildInfo | ConvertTo-Json | Out-File -FilePath "$modulePath/buildinfo.json" -Encoding UTF8

Write-Host ""
Write-Host "Build Summary" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan
Write-Host "Module:       $moduleName" -ForegroundColor White
Write-Host "Version:      $moduleVersion" -ForegroundColor White
Write-Host "Output Path:  $OutputPath" -ForegroundColor White
Write-Host "Build Date:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""
Write-Host "Build completed successfully! ✓" -ForegroundColor Green
Write-Host ""
Write-Host "To publish, run: .\publish.ps1 -ApiKey YOUR_API_KEY" -ForegroundColor Yellow
