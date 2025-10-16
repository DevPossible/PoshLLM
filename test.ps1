<#
.SYNOPSIS
    Runs all Pester tests for the PoshLLM module

.DESCRIPTION
    This script runs the complete PoshLLM test suite using Pester 5.x.
    It imports the module, runs all tests, and provides a summary of results.

.PARAMETER Detailed
    Show detailed test output

.PARAMETER Coverage
    Generate code coverage report

.EXAMPLE
    .\test.ps1
    
.EXAMPLE
    .\test.ps1 -Detailed
    
.EXAMPLE
    .\test.ps1 -Coverage
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory=$false)]
    [switch]$Coverage
)

Write-Host "PoshLLM Test Runner" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""

# Check if Pester 5.x is installed
$pesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge '5.0.0' } | Select-Object -First 1

if (-not $pesterModule) {
    Write-Host "Pester 5.x is not installed. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host "Pester 5.x installed successfully!" -ForegroundColor Green
}

# Import Pester 5.x
Import-Module Pester -MinimumVersion 5.0 -Force

# Configure Pester
$config = New-PesterConfiguration

# Set paths
$config.Run.Path = './Tests/*.Tests.ps1'
$config.Run.Exit = $false

# Set output verbosity
if ($Detailed) {
    $config.Output.Verbosity = 'Detailed'
} else {
    $config.Output.Verbosity = 'Normal'
}

# Configure code coverage if requested
if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = './Source/**/*.ps1'
    $config.CodeCoverage.OutputPath = './coverage.xml'
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    Write-Host "Code coverage enabled. Report will be saved to coverage.xml" -ForegroundColor Yellow
    Write-Host ""
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Green
Write-Host ""

$result = Invoke-Pester -Configuration $config

# Display the test summary with proper counts
Write-Host ""
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan

# Extract test counts from the result object
# In Pester 5.x, the result object may not have these properties populated
# Instead, parse the summary line that Pester prints
# or count tests from the result structure
$passedCount = 0
$failedCount = 0
$skippedCount = 0
$totalCount = 0

# Try to get counts from the result object properties first
if ($null -ne $result.PassedCount) {
    $passedCount = [int]$result.PassedCount
    $failedCount = [int]$result.FailedCount
    $skippedCount = [int]$result.SkippedCount
} else {
    # If properties don't work, iterate through all discovered tests
    # Pester stores tests in a nested structure through Containers
    function Get-AllTests {
        param($Item)
        $tests = @()
        if ($Item.Tests) {
            $tests += $Item.Tests
        }
        if ($Item.Blocks) {
            foreach ($block in $Item.Blocks) {
                $tests += Get-AllTests $block
            }
        }
        return $tests
    }
    
    $allTests = @()
    if ($result.Containers) {
        foreach ($container in $result.Containers) {
            $allTests += Get-AllTests $container
        }
    }
    
    foreach ($test in $allTests) {
        if ($test.Result -eq 'Passed') { $passedCount++ }
        elseif ($test.Result -eq 'Failed') { $failedCount++ }
        elseif ($test.Result -eq 'Skipped') { $skippedCount++ }
    }
}

$totalCount = $passedCount + $failedCount + $skippedCount

# If we still don't have counts, try to extract from the output that was already printed
if ($totalCount -eq 0) {
    # Fallback: assume all tests passed based on the final message
    # This is not ideal but Pester already printed the summary
    Write-Host "See Pester output above for test counts (Total: Failed: $failedCount, Passed/Skipped: calculated)" -ForegroundColor Yellow
} else {
    Write-Host "Total Tests: $totalCount" -ForegroundColor White
    Write-Host "Passed: $passedCount" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "Failed: $failedCount" -ForegroundColor Red
    } else {
        Write-Host "Failed: $failedCount" -ForegroundColor Green
    }
    Write-Host "Skipped: $skippedCount" -ForegroundColor Yellow
}
Write-Host ""

# Exit based on Pester's built-in result tracking
# In Pester 5.x, if there are any failures, the result will have failure information
if ($result.FailedCount -gt 0 -or $result.Result -eq 'Failed') {
    Write-Host "Some tests failed! ✗" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed! ✓" -ForegroundColor Green
    exit 0
}
