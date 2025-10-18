#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Reloads the PoshLLM module for local development
.DESCRIPTION
    This script removes the currently loaded PoshLLM module (if any) and 
    imports it fresh from the local source. Useful during development to 
    quickly test changes without restarting PowerShell.
.EXAMPLE
    .\reload.ps1
    Reloads the PoshLLM module from the current directory
.EXAMPLE
    . .\reload.ps1
    Dot-source to reload in the current scope
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Get the module path
$modulePath = Join-Path $PSScriptRoot 'PoshLLM.psd1'

# Check if the module manifest exists
if (-not (Test-Path $modulePath)) {
    Write-Error "Module manifest not found at: $modulePath"
    exit 1
}

Write-Host "Reloading PoshLLM module..." -ForegroundColor Cyan

# Remove the module if it's already loaded
if (Get-Module PoshLLM) {
    Write-Host "  Removing existing module..." -ForegroundColor Yellow
    Remove-Module PoshLLM -Force
}

# Import the module
Write-Host "  Importing module from: $modulePath" -ForegroundColor Yellow
Import-Module $modulePath -Force

# Verify the import
$module = Get-Module PoshLLM
if ($module) {
    Write-Host "✓ PoshLLM module reloaded successfully!" -ForegroundColor Green
    Write-Host "  Version: $($module.Version)" -ForegroundColor Gray
    Write-Host "  Path: $($module.Path)" -ForegroundColor Gray
    
    # Show exported commands
    $commands = Get-Command -Module PoshLLM
    Write-Host "  Exported Commands: $($commands.Count)" -ForegroundColor Gray
    $commands | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor DarkGray }
} else {
    Write-Error "Failed to reload PoshLLM module"
    exit 1
}
