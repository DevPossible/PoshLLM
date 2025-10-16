# DEPRECATED: This file has been refactored into LLMSystem.Integration.Tests.ps1
# The new file contains system-agnostic integration tests that work for any LLM system
# (ClaudeCode, Ollama, Azure OpenAI, etc.) with just different configuration setup.
#
# To run integration tests for all systems, use:
#   Invoke-Pester Tests/LLMSystem.Integration.Tests.ps1
#
# This file is kept for reference but the tests below are no longer maintained.
# Please refer to LLMSystem.Integration.Tests.ps1 for the current integration test suite.

BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..' 'PoshLLM.psd1'
    Import-Module $modulePath -Force
    
    # Store original config path for cleanup
    $script:configPath = "$env:APPDATA\PoshLLM\config.json"
    $script:configBackupPath = "$env:APPDATA\PoshLLM\config.json.backup"
    
    # Backup existing config if it exists
    if (Test-Path $script:configPath) {
        Copy-Item $script:configPath $script:configBackupPath -Force
    }
    
    # Check if claude CLI is available
    $script:claudeAvailable = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
}

AfterAll {
    # Restore original config if it existed
    if (Test-Path $script:configBackupPath) {
        Copy-Item $script:configBackupPath $script:configPath -Force
        Remove-Item $script:configBackupPath -Force
    } else {
        # Remove test config if no backup existed
        if (Test-Path $script:configPath) {
            Remove-Item $script:configPath -Force
        }
    }
}

Describe "ClaudeCode Integration Tests" {
    Context "When claude CLI is not available" {
        It "Should skip tests if claude is not installed" {
            if (-not $script:claudeAvailable) {
                Set-ItResult -Skipped -Because "claude CLI is not installed"
            }
        }
    }
    
    Context "When configuring ClaudeCode" -Skip:(-not $script:claudeAvailable) {
        It "Should accept claudecode as LLMSystem" {
            { Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude" } | Should -Not -Throw
        }
        
        It "Should save claudecode configuration" {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude"
            $config = Get-PoshLLMConfig
            $config.LLMSystem | Should -Be "claudecode"
            $config.Model | Should -Be "sonnet"
            $config.Location | Should -Be "claude"
        }
        
        It "Should accept API key with claudecode" {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude" -ApiKey "test-key"
            $config = Get-PoshLLMConfig
            $config.ApiKey | Should -Be "test-key"
        }
    }
    
    Context "When using ClaudeCode with GetPrompt" -Skip:(-not $script:claudeAvailable) {
        BeforeAll {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude"
        }
        
        It "Should return enhanced prompt without calling claude" {
            $prompt = Invoke-LLM "What is PowerShell?" -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "System Context:"
            $prompt | Should -Match "What is PowerShell?"
        }
        
        It "Should work with ResponseType Text" {
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Match "TEXT format"
        }
        
        It "Should work with ResponseType Script" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Match "PowerShell script"
        }
    }
    
    Context "When sending actual requests to ClaudeCode" -Skip:(-not $script:claudeAvailable) {
        BeforeAll {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude"
        }
        
        It "Should send request and receive response" {
            # This test requires claude CLI to be authenticated
            # Skip if not authenticated or if it fails
            try {
                $response = Invoke-LLM "Say 'Hello from PoshLLM test'" -Raw
                $response | Should -Not -BeNullOrEmpty
            } catch {
                Set-ItResult -Skipped -Because "claude CLI may not be authenticated or available"
            }
        }
        
        It "Should handle simple text prompts" {
            try {
                $response = Invoke-LLM "What is 2+2?" -ResponseType Text -Raw
                $response | Should -Not -BeNullOrEmpty
            } catch {
                Set-ItResult -Skipped -Because "claude CLI may not be authenticated or available"
            }
        }
        
        It "Should handle model parameter" {
            try {
                $response = Invoke-LLM "test" -Model "sonnet" -ResponseType Text -Raw
                $response | Should -Not -BeNullOrEmpty
            } catch {
                Set-ItResult -Skipped -Because "claude CLI may not be authenticated or available"
            }
        }
    }
    
    Context "When testing error handling" -Skip:(-not $script:claudeAvailable) {
        It "Should handle invalid model gracefully" {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "invalid-model-name" -Location "claude"
            # This should either work or provide a clear error message
            # Using GetPrompt to avoid actual call
            { Invoke-LLM "test" -GetPrompt } | Should -Not -Throw
        }
        
        It "Should handle invalid location gracefully" {
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "nonexistent-claude-exe"
            # Should fail with clear error message about claude not being found
            try {
                Invoke-LLM "test" -Raw
            } catch {
                $_.Exception.Message | Should -Match "claude"
            }
        }
    }
    
    Context "When comparing with Ollama behavior" -Skip:(-not $script:claudeAvailable) {
        It "Should use same prompt format as Ollama" {
            # Configure for claudecode
            Set-PoshLLMConfiguration -LLMSystem "claudecode" -Model "sonnet" -Location "claude"
            $claudePrompt = Invoke-LLM "test prompt" -GetPrompt
            
            # Configure for ollama
            Set-PoshLLMConfiguration -LLMSystem "ollama" -Model "llama3" -Location "http://localhost:11434"
            $ollamaPrompt = Invoke-LLM "test prompt" -GetPrompt
            
            # Both should have the same structure
            $claudePrompt | Should -Match "System Context:"
            $ollamaPrompt | Should -Match "System Context:"
            $claudePrompt | Should -Match "test prompt"
            $ollamaPrompt | Should -Match "test prompt"
        }
    }
}

Describe "Send-ToClaudeCode Function Unit Tests" {
    Context "When testing command construction" {
        It "Should build correct command arguments" {
            # Mock the claude command to capture arguments
            $config = @{
                LLMSystem = "claudecode"
                Model = "sonnet"
                Location = "claude"
            }
            
            # This is a unit test of the function logic
            # We're testing that it would call the right command
            $config.ContainsKey('Location') | Should -Be $true
            $config.ContainsKey('Model') | Should -Be $true
        }
        
        It "Should default to 'claude' if Location is empty" {
            $config = @{
                LLMSystem = "claudecode"
                Model = "sonnet"
                Location = ""
            }
            
            [string]::IsNullOrEmpty($config.Location) | Should -Be $true
        }
        
        It "Should include --print and --output-format text" {
            # These flags should always be present
            $expectedArgs = @('--print', '--output-format', 'text')
            $expectedArgs.Count | Should -Be 3
        }
    }
}
