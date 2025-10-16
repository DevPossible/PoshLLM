# Integration tests for PoshLLM module
# These tests verify the module's functionality with actual LLM interactions

Write-Host "Running PoshLLM Integration Tests..." -ForegroundColor Green

# Import the module
try {
    Import-Module .\PoshLLM.psd1 -Force
    Write-Host "Module imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Information question
Write-Host "`nTest 1: Information question - 'What is the capital of Egypt?'" -ForegroundColor Yellow
try {
    $result = Invoke-LLM -Prompt "What is the capital of Egypt?" -ErrorAction Stop
    Write-Host "Information test completed successfully!" -ForegroundColor Green
    Write-Host "Result: $result" -ForegroundColor Cyan
}
catch {
    Write-Host "Information test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Code generation question
Write-Host "`nTest 2: Code generation - 'Get all the files in this folder that are smaller than 1/2 the largest file'" -ForegroundColor Yellow
try {
    $result = Invoke-LLM -Prompt "Get all the files in this folder that are smaller than 1/2 the largest file" -ErrorAction Stop
    Write-Host "Code generation test completed successfully!" -ForegroundColor Green
    Write-Host "Result: $result" -ForegroundColor Cyan
}
catch {
    Write-Host "Code generation test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nIntegration tests completed!" -ForegroundColor Green
Write-Host "Note: The code generation test will prompt for user action (execute/copy/exit) if code is returned." -ForegroundColor Yellow
