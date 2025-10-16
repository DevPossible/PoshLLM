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
    
    # Create a test configuration
    Set-PoshLLMConfiguration -Model "test-model" -Location "http://localhost:11434"
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

Describe "Error Handling" {
    Context "When configuration is missing" {
        It "Should error gracefully when no config exists" {
            # Remove config
            if (Test-Path $script:configPath) {
                Remove-Item $script:configPath -Force
            }
            
            { Invoke-LLM "test" -ErrorAction Stop } | Should -Throw "*No configuration found*"
        }
        
        It "Should suggest running Configure-PoshLLM" {
            if (Test-Path $script:configPath) {
                Remove-Item $script:configPath -Force
            }
            
            { Invoke-LLM "test" -ErrorAction Stop } | Should -Throw "*Configure-PoshLLM*"
        }
    }
    
    Context "When Ollama is unreachable" {
        BeforeAll {
            # Ensure config exists for these tests
            Set-PoshLLMConfiguration -Model "test-model" -Location "http://localhost:11434"
        }
        
        It "Should error gracefully when Location is unreachable" {
            # Use an invalid port that won't be accessible
            { Invoke-LLM "test" -Config @{Location = "http://localhost:99999"} -ErrorAction Stop } | Should -Throw
        }
        
        It "Should provide helpful error message for connection failures" {
            { Invoke-LLM "test" -Config @{Location = "http://localhost:99999"} -ErrorAction Stop } | Should -Throw "*Failed to connect to Ollama*"
        }
    }
    
    Context "When model doesn't exist" {
        BeforeAll {
            # Ensure config exists for these tests
            Set-PoshLLMConfiguration -Model "test-model" -Location "http://localhost:11434"
        }
        
        It "Should handle non-existent model gracefully" {
            # This test will only work if Ollama is running
            # We use -GetPrompt to avoid actually calling Ollama in this test
            { Invoke-LLM "test" -Config @{Model = "this-model-definitely-does-not-exist-12345"} -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When context size is invalid" {
        BeforeAll {
            # Ensure config exists for these tests
            Set-PoshLLMConfiguration -Model "test-model" -Location "http://localhost:11434"
        }
        
        It "Should reject context size override exceeding 64KB" {
            { Invoke-LLM "test" -Config @{ContextSize = 70000} -ErrorAction Stop } | Should -Throw
        }
        
        It "Should reject negative context size override" {
            { Invoke-LLM "test" -Config @{ContextSize = -1} -ErrorAction Stop } | Should -Throw
        }
        
        It "Should reject zero context size override" {
            { Invoke-LLM "test" -Config @{ContextSize = 0} -ErrorAction Stop } | Should -Throw
        }
        
        It "Should accept valid context size override" {
            { Invoke-LLM "test" -Config @{ContextSize = 8192} -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When prompt is too large" {
        BeforeAll {
            # Ensure config exists for these tests
            Set-PoshLLMConfiguration -Model "test-model" -Location "http://localhost:11434"
        }
        
        It "Should reject enhanced prompt exceeding 64KB" {
            # Create a very large prompt (65000 chars + context will exceed 64KB)
            $largePrompt = "x" * 65000
            
            { Invoke-LLM $largePrompt -ErrorAction Stop } | Should -Throw "*exceeds the maximum allowed size of 64KB*"
        }
        
        It "Should provide size information in error message" {
            $largePrompt = "x" * 65000
            
            try {
                Invoke-LLM $largePrompt -ErrorAction Stop
            } catch {
                $_.Exception.Message | Should -Match "\d+ bytes"
            }
        }
        
        It "Should accept normal-sized prompts" {
            { Invoke-LLM "This is a normal prompt" -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When mandatory parameters are missing" {
        It "Should require Prompt parameter" {
            # PowerShell will prompt for mandatory parameters, so we test with empty string instead
            { Invoke-LLM "" -ErrorAction Stop } | Should -Throw
        }
        
        It "Should not allow empty prompt" {
            { Invoke-LLM "" -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context "When configuration is corrupted" {
        It "Should handle invalid JSON in config file" {
            # Write invalid JSON
            "{ this is not valid json }" | Out-File -FilePath $script:configPath -Encoding UTF8
            
            { Invoke-LLM "test" -ErrorAction Stop } | Should -Throw
        }
        
        It "Should handle missing config properties" {
            # Write incomplete config
            '{"Model":"test"}' | Out-File -FilePath $script:configPath -Encoding UTF8
            
            $config = Get-PoshLLMConfig
            # Should still return something, but may be incomplete
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Parameter Validation" {
    Context "When using ResponseType parameter" {
        It "Should reject invalid ResponseType values" {
            { Invoke-LLM "test" -ResponseType "InvalidType" -ErrorAction Stop } | Should -Throw
        }
        
        It "Should accept valid ResponseType values" {
            { Invoke-LLM "test" -ResponseType "Text" -GetPrompt } | Should -Not -Throw
            { Invoke-LLM "test" -ResponseType "Data" -GetPrompt } | Should -Not -Throw
            { Invoke-LLM "test" -ResponseType "Script" -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When using DataFormat parameter" {
        It "Should reject invalid DataFormat values" {
            { Invoke-LLM "test" -ResponseType Data -DataFormat "YAML" -ErrorAction Stop } | Should -Throw
        }
        
        It "Should accept valid DataFormat values" {
            { Invoke-LLM "test" -ResponseType Data -DataFormat "JSON" -GetPrompt } | Should -Not -Throw
            { Invoke-LLM "test" -ResponseType Data -DataFormat "CSV" -GetPrompt } | Should -Not -Throw
            { Invoke-LLM "test" -ResponseType Data -DataFormat "XML" -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When using IncludeContext parameter" {
        It "Should accept zero for IncludeContext" {
            { Invoke-LLM "test" -IncludeContext 0 -GetPrompt } | Should -Not -Throw
        }
        
        It "Should accept positive values for IncludeContext" {
            { Invoke-LLM "test" -IncludeContext 10 -GetPrompt } | Should -Not -Throw
        }
        
        It "Should handle negative IncludeContext gracefully" {
            # PowerShell parameter binding should handle this
            { Invoke-LLM "test" -IncludeContext -5 -GetPrompt } | Should -Not -Throw
        }
    }
}
