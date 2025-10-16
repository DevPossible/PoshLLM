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

Describe "Invoke-LLM -GetPrompt Switch" {
    Context "When using -GetPrompt without IncludeContext" {
        It "Should return prompt without calling LLM" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should contain System Context section" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Match "System Context:"
        }
        
        It "Should contain PowerShell version" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Match "PowerShell Version:"
        }
        
        It "Should contain Operating System information" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Match "Operating System:"
        }
        
        It "Should contain Instructions for Response Format section" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Match "Instructions for Response Format:"
        }
        
        It "Should contain User Request section" {
            $prompt = Invoke-LLM "test prompt" -GetPrompt
            $prompt | Should -Match "User Request:"
        }
        
        It "Should include the actual user prompt" {
            $prompt = Invoke-LLM "my unique test prompt 12345" -GetPrompt
            $prompt | Should -Match "my unique test prompt 12345"
        }
    }
    
    Context "When using -GetPrompt with -IncludeContext" {
        It "Should include console context when history is available" {
            # The IncludeContext feature includes command history
            # We just verify it doesn't throw and returns a prompt
            $prompt = Invoke-LLM "test" -IncludeContext 3 -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should not fail when no history is available" {
            # Clear history
            Clear-History -ErrorAction SilentlyContinue
            
            { Invoke-LLM "test" -IncludeContext 5 -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When using -GetPrompt with -ResponseType Text" {
        It "Should include TEXT format instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Match "TEXT format"
        }
        
        It "Should not include Script or Data format instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Not -Match "PowerShell script"
            $prompt | Should -Not -Match "JSON format"
        }
    }
    
    Context "When using -GetPrompt with -ResponseType Data" {
        It "Should include JSON format instructions by default" {
            $prompt = Invoke-LLM "test" -ResponseType Data -GetPrompt
            $prompt | Should -Match "JSON format"
        }
        
        It "Should include CSV format instructions when specified" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat CSV -GetPrompt
            $prompt | Should -Match "CSV format"
        }
        
        It "Should include XML format instructions when specified" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat XML -GetPrompt
            $prompt | Should -Match "XML format"
        }
    }
    
    Context "When using -GetPrompt with -ResponseType Script" {
        It "Should include PowerShell script instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Match "PowerShell script"
        }
        
        It "Should include code block instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Match "code block using triple backticks"
        }
        
        It "Should include PowerShell version in instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $psVersion = $PSVersionTable.PSVersion.ToString()
            $prompt | Should -Match $psVersion
        }
    }
    
    Context "When using -GetPrompt with auto-detection (no ResponseType)" {
        It "Should include all three response type instructions" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "REQUEST FOR INFORMATION"
            $prompt | Should -Match "REQUEST FOR DATA"
            $prompt | Should -Match "REQUEST TO ACCOMPLISH A TASK"
        }
    }
    
    Context "When validating prompt size with -GetPrompt" {
        It "Should not throw error for normal-sized prompts" {
            $normalPrompt = "This is a normal test prompt"
            { Invoke-LLM $normalPrompt -GetPrompt } | Should -Not -Throw
        }
        
        It "Should return prompt even if it would be large" {
            # Create a large prompt
            $largePrompt = "x" * 50000
            $result = Invoke-LLM $largePrompt -GetPrompt
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Prompt Size Validation" {
    Context "When prompt size exceeds 64KB" {
        It "Should throw error when enhanced prompt exceeds 64KB" {
            # Create a prompt that will exceed 64KB when enhanced (65000 chars + context)
            $largePrompt = "x" * 65000
            
            { Invoke-LLM $largePrompt -ErrorAction Stop } | Should -Throw "*exceeds the maximum allowed size of 64KB*"
        }
        
        It "Should calculate prompt size in bytes correctly" {
            $testPrompt = "test"
            $enhancedPrompt = Invoke-LLM $testPrompt -GetPrompt
            $sizeBytes = [System.Text.Encoding]::UTF8.GetByteCount($enhancedPrompt)
            
            $sizeBytes | Should -BeLessThan 65536
        }
    }
}
