# PoshLLM Test Suite

## Overview

This directory contains comprehensive tests for the PoshLLM module using the Pester testing framework.

## Test Files

### Unit Tests

1. **Configuration.Tests.ps1** - Tests configuration management
   - Configuration file creation and reading
   - Context size validation (64KB limit)
   - Invalid configuration handling
   - Configuration overrides

2. **GetPrompt.Tests.ps1** - Tests the -GetPrompt switch functionality
   - Prompt construction and structure
   - System context inclusion
   - Console history inclusion with -IncludeContext
   - Format instructions for different ResponseTypes
   - Prompt size validation

3. **ErrorHandling.Tests.ps1** - Tests error handling scenarios
   - Missing configuration
   - Ollama connectivity issues
   - Invalid model names
   - Context size violations
   - Oversized prompts
   - Parameter validation

4. **Parameters.Tests.ps1** - Tests all Invoke-LLM parameters
   - ResponseType (Text, Data, Script)
   - DataFormat (JSON, CSV, XML)
   - IncludeContext
   - Raw switch
   - Parameter overrides (Model, URL, ContextSize, LLMSystem)
   - Parameter combinations

5. **AutoDetection.Tests.ps1** - Tests auto-detection of response types
   - Information request detection
   - Data request detection
   - Task/script request detection
   - Auto-detection prompt structure
   - Real-world prompt scenarios

### Legacy Tests

- **Test-PoshLLM.ps1** - Basic module loading test (legacy)
- **Test-PoshLLM-Enhanced.ps1** - Function availability test (legacy)
- **Integration-Tests.ps1** - Basic integration tests (legacy, requires Ollama running)

## Prerequisites

### Install Pester

```powershell
# Install Pester 5.x
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck
```

### Verify Pester Installation

```powershell
Get-Module -Name Pester -ListAvailable
```

## Running Tests

### Run All Tests

```powershell
# From the repository root
Invoke-Pester -Path ./Tests/*.Tests.ps1
```

### Run Specific Test File

```powershell
# Configuration tests
Invoke-Pester -Path ./Tests/Configuration.Tests.ps1

# GetPrompt tests
Invoke-Pester -Path ./Tests/GetPrompt.Tests.ps1

# Error handling tests
Invoke-Pester -Path ./Tests/ErrorHandling.Tests.ps1

# Parameter tests
Invoke-Pester -Path ./Tests/Parameters.Tests.ps1

# Auto-detection tests
Invoke-Pester -Path ./Tests/AutoDetection.Tests.ps1
```

### Run Tests with Detailed Output

```powershell
Invoke-Pester -Path ./Tests/*.Tests.ps1 -Output Detailed
```

### Run Tests with Code Coverage

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './Tests/*.Tests.ps1'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './Source/**/*.ps1'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

## Test Organization

### Test Structure

All new tests follow the Pester convention:

```powershell
BeforeAll {
    # Setup: Import module, backup config, create test config
}

Describe "Feature Name" {
    Context "When specific condition" {
        It "Should behave in expected way" {
            # Test assertion
        }
    }
}

AfterAll {
    # Cleanup: Restore config
}
```

### Test Isolation

- Each test file backs up and restores the configuration
- Tests use `-GetPrompt` to avoid calling Ollama when possible
- Configuration changes are isolated per test file

## Important Notes

### Tests That Don't Require Ollama

Most tests use the `-GetPrompt` switch to test functionality without requiring a running Ollama instance:

- Configuration.Tests.ps1 - No Ollama needed
- GetPrompt.Tests.ps1 - No Ollama needed
- ErrorHandling.Tests.ps1 - Partially (some tests check connectivity)
- Parameters.Tests.ps1 - No Ollama needed
- AutoDetection.Tests.ps1 - No Ollama needed

### Tests That Require Ollama

- Integration-Tests.ps1 (legacy) - **Requires Ollama running**
- Some error handling tests that verify Ollama connectivity

### Configuration Backup

All tests automatically:
1. Backup your existing configuration before running
2. Create a temporary test configuration
3. Restore your original configuration after completion

## Test Coverage

### What IS Tested ✅

1. **Configuration Management**
   - File creation and reading
   - 64KB context size validation
   - Invalid configuration handling
   - Default values

2. **Error Handling**
   - Missing configuration
   - Connection failures
   - Invalid parameters
   - Oversized prompts

3. **Parameters**
   - All ResponseType values
   - All DataFormat values
   - IncludeContext functionality
   - Raw switch
   - GetPrompt switch
   - Parameter overrides

4. **Prompt System**
   - Prompt construction
   - System context inclusion
   - Console history integration
   - Format instructions

5. **Auto-Detection**
   - Information request detection
   - Data request detection
   - Task request detection
   - Real-world scenarios

### What IS NOT Tested ❌

1. **Actual LLM Responses** - Most tests use `-GetPrompt` to avoid calling Ollama
2. **Code Execution** - Interactive prompts and code execution are not tested
3. **Clipboard Operations** - Copy to clipboard functionality
4. **Syntax Highlighting** - Display formatting functions

## Continuous Integration

### Run Tests in CI/CD

```powershell
# Install module
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# Run tests with CI-friendly output
$config = New-PesterConfiguration
$config.Run.Path = './Tests/*.Tests.ps1'
$config.Run.Exit = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = './TestResults.xml'
Invoke-Pester -Configuration $config
```

## Troubleshooting

### Test Failures

If tests fail, check:

1. **Pester Version** - Ensure Pester 5.x is installed
2. **Module Import** - Verify the module can be imported
3. **Configuration Path** - Check that `$env:APPDATA\PoshLLM` is accessible
4. **File Permissions** - Ensure tests can write to config directory

### Common Issues

**Issue**: Tests fail with "Module not found"
- **Solution**: Run tests from repository root directory

**Issue**: Tests fail with "Cannot find PoshLLM.psd1"
- **Solution**: Ensure module manifest exists in repository root

**Issue**: Configuration tests fail
- **Solution**: Ensure you have write permissions to `$env:APPDATA\PoshLLM`

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Use Pester 5.x syntax
3. Include proper setup/cleanup in BeforeAll/AfterAll
4. Use `-GetPrompt` when possible to avoid requiring Ollama
5. Add descriptive test names
6. Update this README with new test coverage

## Test Results Summary

Expected test counts (approximate):

- Configuration.Tests.ps1: ~15 tests
- GetPrompt.Tests.ps1: ~25 tests
- ErrorHandling.Tests.ps1: ~20 tests
- Parameters.Tests.ps1: ~30 tests
- AutoDetection.Tests.ps1: ~25 tests

**Total**: ~115 tests

All tests should pass on a clean system with proper Pester installation.
