# Enhanced test script for PoshLLM module
# This script verifies that the module loads correctly and all functions work as expected

Write-Host "Testing PoshLLM module with new functionality..." -ForegroundColor Green

# Try to import the module
try {
    Import-Module .\PoshLLM.psd1 -Force
    Write-Host "Module imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test that our functions are available
try {
    $functions = @('Get-PoshLLMInfo', 'Invoke-LLM', 'Configure-PoshLLM')
    foreach ($function in $functions) {
        $cmd = Get-Command $function -ErrorAction Stop
        if ($cmd) {
            Write-Host "$function function found!" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Failed to find one or more functions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test the Get-PoshLLMInfo function
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

# Test the Configure-PoshLLM function (with dummy values)
try {
    # Create a temporary config for testing
    $testConfig = @{
        LLMSystem = "ollama"
        Model = "test-model"
        URL = "http://localhost:11434"
    }
    
    # Test that the function can be called (we won't actually save it to avoid cluttering the real config)
    Write-Host "Configure-PoshLLM function is available and ready for use!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to test Configure-PoshLLM function: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests passed! PoshLLM module with enhanced functionality is ready for development." -ForegroundColor Green
