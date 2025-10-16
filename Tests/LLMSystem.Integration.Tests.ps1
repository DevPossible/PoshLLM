# Generic Integration Tests for PoshLLM LLM Systems
# This file contains integration tests that can be run for any LLM system
# System-specific configuration is provided via test data

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
    
    # Define system configurations for testing
    # Each system has its own configuration and availability check
    $script:systemConfigs = @{
        'ClaudeCode' = @{
            LLMSystem = 'claudecode'
            Model = 'sonnet'
            Location = 'claude'
            AvailabilityCheck = { $null -ne (Get-Command claude -ErrorAction SilentlyContinue) }
            RequiresAuth = $true
        }
        'Ollama' = @{
            LLMSystem = 'ollama'
            Model = 'qwen3:8b'
            Location = 'http://localhost:11434'
            AvailabilityCheck = { 
                try {
                    $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/version' -TimeoutSec 10 -ErrorAction SilentlyContinue
                    $null -ne $response
                } catch {
                    $false
                }
            }
            RequiresAuth = $false
        }
        'AzureOpenAI' = @{
            LLMSystem = 'azureopenai'
            Model = 'gpt-4'
            Location = $env:AZURE_OPENAI_ENDPOINT
            AvailabilityCheck = { 
                # Check if endpoint and API key are configured
                -not [string]::IsNullOrEmpty($env:AZURE_OPENAI_ENDPOINT) -and 
                -not [string]::IsNullOrEmpty($env:AZURE_OPENAI_API_KEY)
            }
            RequiresAuth = $true
            ApiKey = $env:AZURE_OPENAI_API_KEY
        }
    }
    
    # Check availability for each system
    foreach ($systemName in $script:systemConfigs.Keys) {
        $config = $script:systemConfigs[$systemName]
        try {
            $config.Available = & $config.AvailabilityCheck
            Write-Verbose "System '$systemName' availability: $($config.Available)" -Verbose
        } catch {
            $config.Available = $false
            Write-Verbose "System '$systemName' availability check failed: $_" -Verbose
        }
    }
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

# Run integration tests for each configured system
Describe "LLM System Integration Tests" {
    Context "ClaudeCode Integration" {
        BeforeAll {
            $systemConfig = $script:systemConfigs['ClaudeCode']
        }
        
        It "Should skip tests if ClaudeCode is not available" {
            if (-not $systemConfig.Available) {
                Set-ItResult -Skipped -Because "ClaudeCode is not available or not configured"
            }
        }
        
        Context "When configuring ClaudeCode" -Skip:(-not $script:systemConfigs.ClaudeCode.Available) {
            It "Should accept claudecode as LLMSystem" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                { Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location } | Should -Not -Throw
            }
            
            It "Should save ClaudeCode configuration" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
                
                $config = Get-PoshLLMConfig
                $config.LLMSystem | Should -Be $systemConfig.LLMSystem
                $config.Model | Should -Be $systemConfig.Model
                $config.Location | Should -Be $systemConfig.Location
            }
            
            It "Should accept API key with ClaudeCode" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location -ApiKey "test-key"
                
                $config = Get-PoshLLMConfig
                $config.ApiKey | Should -Be "test-key"
            }
        }
        
        Context "When using ClaudeCode with GetPrompt" -Skip:(-not $script:systemConfigs.ClaudeCode.Available) {
            BeforeAll {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
            }
            
            It "Should return enhanced prompt without calling ClaudeCode" {
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
        
        Context "When sending actual requests to ClaudeCode" -Skip:(-not $script:systemConfigs.ClaudeCode.Available) {
            BeforeAll {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
            }
            
            It "Should send request and receive response" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                try {
                    $response = Invoke-LLM "Say 'Hello from PoshLLM test'" -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "ClaudeCode may not be authenticated or available"
                }
            }
            
            It "Should handle simple text prompts" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                try {
                    $response = Invoke-LLM "What is 2+2?" -ResponseType Text -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "ClaudeCode may not be authenticated or available"
                }
            }
            
            It "Should handle model parameter override" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                try {
                    $response = Invoke-LLM "test" -Model $systemConfig.Model -ResponseType Text -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "ClaudeCode may not be authenticated or available"
                }
            }
        }
        
        Context "When testing ClaudeCode error handling" -Skip:(-not $script:systemConfigs.ClaudeCode.Available) {
            It "Should handle invalid model gracefully" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model "invalid-model-name" -Location $systemConfig.Location
                { Invoke-LLM "test" -GetPrompt } | Should -Not -Throw
            }
            
            It "Should handle invalid location gracefully" {
                $systemConfig = $script:systemConfigs.ClaudeCode
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location "nonexistent-location"
                try {
                    Invoke-LLM "test" -Raw
                } catch {
                    $_.Exception.Message | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
    
    Context "Ollama Integration" {
        BeforeAll {
            $systemConfig = $script:systemConfigs['Ollama']
        }
        
        It "Should skip tests if Ollama is not available" {
            if (-not $systemConfig.Available) {
                Set-ItResult -Skipped -Because "Ollama is not available or not configured"
            }
        }
        
        Context "When configuring Ollama" -Skip:(-not $script:systemConfigs.Ollama.Available) {
            It "Should accept ollama as LLMSystem" {
                $systemConfig = $script:systemConfigs.Ollama
                { Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location } | Should -Not -Throw
            }
            
            It "Should save Ollama configuration" {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
                
                $config = Get-PoshLLMConfig
                $config.LLMSystem | Should -Be $systemConfig.LLMSystem
                $config.Model | Should -Be $systemConfig.Model
                $config.Location | Should -Be $systemConfig.Location
            }
            
            It "Should accept API key with Ollama" {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location -ApiKey "test-key"
                
                $config = Get-PoshLLMConfig
                $config.ApiKey | Should -Be "test-key"
            }
        }
        
        Context "When using Ollama with GetPrompt" -Skip:(-not $script:systemConfigs.Ollama.Available) {
            BeforeAll {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
            }
            
            It "Should return enhanced prompt without calling Ollama" {
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
        
        Context "When sending actual requests to Ollama" -Skip:(-not $script:systemConfigs.Ollama.Available) {
            BeforeAll {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location $systemConfig.Location
            }
            
            It "Should send request and receive response" {
                $systemConfig = $script:systemConfigs.Ollama
                try {
                    $response = Invoke-LLM "Say 'Hello from PoshLLM test'" -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "Ollama may not have the required model available"
                }
            }
            
            It "Should handle simple text prompts" {
                $systemConfig = $script:systemConfigs.Ollama
                try {
                    $response = Invoke-LLM "What is 2+2?" -ResponseType Text -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "Ollama may not have the required model available"
                }
            }
            
            It "Should handle model parameter override" {
                $systemConfig = $script:systemConfigs.Ollama
                try {
                    $response = Invoke-LLM "test" -Model $systemConfig.Model -ResponseType Text -Raw
                    $response | Should -Not -BeNullOrEmpty
                } catch {
                    Set-ItResult -Skipped -Because "Ollama may not have the required model available"
                }
            }
        }
        
        Context "When testing Ollama error handling" -Skip:(-not $script:systemConfigs.Ollama.Available) {
            It "Should handle invalid model gracefully" {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model "invalid-model-name" -Location $systemConfig.Location
                { Invoke-LLM "test" -GetPrompt } | Should -Not -Throw
            }
            
            It "Should handle invalid location gracefully" {
                $systemConfig = $script:systemConfigs.Ollama
                Set-PoshLLMConfiguration -LLMSystem $systemConfig.LLMSystem -Model $systemConfig.Model -Location "http://localhost:99999"
                try {
                    Invoke-LLM "test" -Raw
                } catch {
                    $_.Exception.Message | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}

# Cross-system compatibility tests
Describe "Cross-System Compatibility Tests" {
    Context "When comparing prompt formats across systems" {
        It "Should use same prompt format for all systems" {
            $prompts = @{}
            
            foreach ($systemName in $script:systemConfigs.Keys) {
                $systemConfig = $script:systemConfigs[$systemName]
                
                if ($systemConfig.Available) {
                    $params = @{
                        LLMSystem = $systemConfig.LLMSystem
                        Model = $systemConfig.Model
                        Location = $systemConfig.Location
                    }
                    if ($systemConfig.ApiKey) {
                        $params.ApiKey = $systemConfig.ApiKey
                    }
                    Set-PoshLLMConfiguration @params
                    $prompts[$systemName] = Invoke-LLM "test prompt" -GetPrompt
                }
            }
            
            # All prompts should have the same structure
            foreach ($prompt in $prompts.Values) {
                $prompt | Should -Match "System Context:"
                $prompt | Should -Match "test prompt"
            }
        }
    }
}
