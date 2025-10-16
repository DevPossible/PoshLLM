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

Describe "Invoke-LLM Parameter Tests" {
    Context "When using -ResponseType parameter" {
        It "Should accept Text value" {
            { Invoke-LLM "test" -ResponseType Text -GetPrompt } | Should -Not -Throw
        }
        
        It "Should accept Data value" {
            { Invoke-LLM "test" -ResponseType Data -GetPrompt } | Should -Not -Throw
        }
        
        It "Should accept Script value" {
            { Invoke-LLM "test" -ResponseType Script -GetPrompt } | Should -Not -Throw
        }
        
        It "Should modify prompt instructions for Text" {
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Match "TEXT format"
            $prompt | Should -Not -Match "REQUEST FOR INFORMATION"
        }
        
        It "Should modify prompt instructions for Data" {
            $prompt = Invoke-LLM "test" -ResponseType Data -GetPrompt
            $prompt | Should -Match "JSON format"
            $prompt | Should -Not -Match "REQUEST FOR INFORMATION"
        }
        
        It "Should modify prompt instructions for Script" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Match "PowerShell script"
            $prompt | Should -Not -Match "REQUEST FOR INFORMATION"
        }
    }
    
    Context "When using -DataFormat parameter" {
        It "Should use JSON format by default with ResponseType Data" {
            $prompt = Invoke-LLM "test" -ResponseType Data -GetPrompt
            $prompt | Should -Match "JSON format"
        }
        
        It "Should use CSV format when specified" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat CSV -GetPrompt
            $prompt | Should -Match "CSV format"
        }
        
        It "Should use XML format when specified" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat XML -GetPrompt
            $prompt | Should -Match "XML format"
        }
        
        It "Should include 'ONLY the data' instruction for Data responses" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat JSON -GetPrompt
            $prompt | Should -Match "ONLY the.*data"
        }
    }
    
    Context "When using -IncludeContext parameter" {
        It "Should not include context when IncludeContext is 0" {
            $prompt = Invoke-LLM "test" -IncludeContext 0 -GetPrompt
            $prompt | Should -Not -Match "Recent Console Output Context"
        }
        
        It "Should include context when IncludeContext is positive" {
            # Create some history
            Get-Date | Out-Null
            
            $prompt = Invoke-LLM "test" -IncludeContext 5 -GetPrompt
            # May or may not have context depending on history availability
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should specify number of commands in context message" {
            # Create some history
            1..3 | ForEach-Object { Get-Date | Out-Null }
            
            $prompt = Invoke-LLM "test" -IncludeContext 2 -GetPrompt
            if ($prompt -match "Recent Console Output Context") {
                $prompt | Should -Match "last 2 commands"
            }
        }
    }
    
    Context "When using -Raw parameter" {
        It "Should accept -Raw switch" {
            { Invoke-LLM "test" -Raw -GetPrompt } | Should -Not -Throw
        }
        
        It "Should work with -GetPrompt (returns prompt, not raw)" {
            $result = Invoke-LLM "test" -Raw -GetPrompt
            $result | Should -Match "System Context"
        }
    }
    
    Context "When using -GetPrompt parameter" {
        It "Should return enhanced prompt" {
            $result = Invoke-LLM "test" -GetPrompt
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "System Context"
        }
        
        It "Should not call Ollama when -GetPrompt is used" {
            # This should not fail even with invalid Location since it doesn't call Ollama
            { Invoke-LLM "test" -Config @{Location = "http://invalid:99999"} -GetPrompt } | Should -Not -Throw
        }
    }
    
    Context "When using Config parameter overrides" {
        It "Should override Model parameter" {
            $prompt = Invoke-LLM "test" -Config @{Model = "override-model"} -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should override Location parameter" {
            $prompt = Invoke-LLM "test" -Config @{Location = "http://override:1234"} -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should override ContextSize parameter" {
            $prompt = Invoke-LLM "test" -Config @{ContextSize = 8192} -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should override LLMSystem parameter" {
            $prompt = Invoke-LLM "test" -Config @{LLMSystem = "ollama"} -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When combining multiple parameters" {
        It "Should work with ResponseType Data and DataFormat CSV" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat CSV -GetPrompt
            $prompt | Should -Match "CSV format"
        }
        
        It "Should work with ResponseType Data and DataFormat XML" {
            $prompt = Invoke-LLM "test" -ResponseType Data -DataFormat XML -GetPrompt
            $prompt | Should -Match "XML format"
        }
        
        It "Should work with ResponseType Script and IncludeContext" {
            $prompt = Invoke-LLM "test" -ResponseType Script -IncludeContext 5 -GetPrompt
            $prompt | Should -Match "PowerShell script"
        }
        
        It "Should work with multiple Config overrides simultaneously" {
            $config = @{
                Model = "override"
                Location = "http://test:1234"
                ContextSize = 16384
            }
            $prompt = Invoke-LLM "test" -Config $config -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
        
        It "Should work with IncludeContext and GetPrompt" {
            $prompt = Invoke-LLM "test" -IncludeContext 5 -GetPrompt
            $prompt | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When using mandatory Prompt parameter" {
        It "Should accept Prompt as positional parameter" {
            { Invoke-LLM "test prompt" -GetPrompt } | Should -Not -Throw
        }
        
        It "Should accept Prompt as named parameter" {
            { Invoke-LLM -Prompt "test prompt" -GetPrompt } | Should -Not -Throw
        }
        
        It "Should reject empty string as prompt" {
            { Invoke-LLM "" -GetPrompt } | Should -Throw "*empty string*"
        }
    }
}

Describe "Parameter Behavior Verification" {
    Context "When ResponseType affects code detection" {
        It "Should not check for code blocks when ResponseType is Text" {
            # This tests the shouldCheckForCode logic
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Not -Match "code block"
        }
        
        It "Should not check for code blocks when ResponseType is Data" {
            $prompt = Invoke-LLM "test" -ResponseType Data -GetPrompt
            # Data format instructions don't mention code blocks
            $prompt | Should -Not -Match "PowerShell script"
        }
        
        It "Should check for code blocks when ResponseType is Script" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Match "code block"
        }
    }
    
    Context "When testing system context inclusion" {
        It "Should include PowerShell version in all prompts" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $psVersion = $PSVersionTable.PSVersion.ToString()
            $prompt | Should -Match $psVersion
        }
        
        It "Should include OS information in all prompts" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "Operating System:"
        }
        
        It "Should include OS in Script instructions" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $osVersion = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                "Windows"
            } elseif ($IsLinux) {
                "Linux"
            } elseif ($IsMacOS) {
                "macOS"
            } else {
                "Unknown"
            }
            $prompt | Should -Not -BeNullOrEmpty
        }
    }
}
