# Test script for PoshLLM module
# This script verifies that the module loads correctly and functions as expected

Write-Host "Testing PoshLLM module..." -ForegroundColor Green

# Try to import the module
try {
    Import-Module .\PoshLLM.psd1 -Force
    Write-Host "Module imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test that our function is available
try {
    $function = Get-Command Get-PoshLLMInfo -ErrorAction Stop
    if ($function) {
        Write-Host "Get-PoshLLMInfo function found!" -ForegroundColor Green
    }
}
catch {
    Write-Host "Failed to find Get-PoshLLMInfo function: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test the function
try {
    $info = Get-PoshLLMInfo
    if ($info) {
        Write-Host "Get-PoshLLMInfo function works correctly!" -ForegroundColor Green
        Write-Host "Module Name: $($info.Name)" -ForegroundColor Yellow
        Write-Host "Module Version: $($info.Version)" -ForegroundColor Yellow
        Write-Host "Module Description: $($info.Description)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Failed to execute Get-PoshLLMInfo function: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests passed! PoshLLM module is ready for development." -ForegroundColor Green
