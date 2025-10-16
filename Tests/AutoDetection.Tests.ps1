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
    Set-PoshLLMConfiguration -Model "test-model" -URL "http://localhost:11434"
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

Describe "Auto-Detection of Response Types" {
    Context "When prompt is for information (no explicit ResponseType)" {
        It "Should include all three response type instructions" {
            $prompt = Invoke-LLM "What is PowerShell?" -GetPrompt
            $prompt | Should -Match "REQUEST FOR INFORMATION"
            $prompt | Should -Match "REQUEST FOR DATA"
            $prompt | Should -Match "REQUEST TO ACCOMPLISH A TASK"
        }
        
        It "Should include TEXT format instructions" {
            $prompt = Invoke-LLM "What is the capital of France?" -GetPrompt
            $prompt | Should -Match "TEXT format"
        }
        
        It "Should include auto-detection logic for questions" {
            $prompt = Invoke-LLM "Explain how DNS works" -GetPrompt
            $prompt | Should -Match "REQUEST FOR INFORMATION"
        }
    }
    
    Context "When prompt is for data (no explicit ResponseType)" {
        It "Should include data format instructions" {
            $prompt = Invoke-LLM "List 5 programming languages" -GetPrompt
            $prompt | Should -Match "REQUEST FOR DATA"
        }
        
        It "Should suggest JSON as default for data" {
            $prompt = Invoke-LLM "Give me a list of colors" -GetPrompt
            $prompt | Should -Match "JSON format"
        }
        
        It "Should respect explicit format requests in prompt" {
            $prompt = Invoke-LLM "List 10 cities in CSV format" -GetPrompt
            $prompt | Should -Match "CSV"
        }
    }
    
    Context "When prompt is for task/script (no explicit ResponseType)" {
        It "Should include PowerShell script instructions" {
            $prompt = Invoke-LLM "List all running processes" -GetPrompt
            $prompt | Should -Match "PowerShell script"
        }
        
        It "Should mention code blocks with triple backticks" {
            $prompt = Invoke-LLM "Get all files larger than 100MB" -GetPrompt
            $prompt | Should -Match "triple backticks"
        }
        
        It "Should include system administration task examples" {
            $prompt = Invoke-LLM "Check which ports are listening" -GetPrompt
            $prompt | Should -Match "system-level operations"
            $prompt | Should -Match "processes"
            $prompt | Should -Match "ports"
        }
        
        It "Should include PowerShell version in script instructions" {
            $prompt = Invoke-LLM "Show disk usage" -GetPrompt
            $psVersion = $PSVersionTable.PSVersion.ToString()
            $prompt | Should -Match $psVersion
        }
    }
    
    Context "When testing auto-detection prompt structure" {
        It "Should include IF-THEN logic for information requests" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "If this is a REQUEST FOR INFORMATION"
        }
        
        It "Should include IF-THEN logic for data requests" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "If this is a REQUEST FOR DATA"
        }
        
        It "Should include IF-THEN logic for task requests" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "If this is a REQUEST TO ACCOMPLISH A TASK"
        }
        
        It "Should use newlines to separate instructions" {
            $prompt = Invoke-LLM "test" -GetPrompt
            # Should have proper formatting with newlines
            $prompt | Should -Match "REQUEST FOR INFORMATION.*\n.*REQUEST FOR DATA"
        }
    }
    
    Context "When explicit ResponseType overrides auto-detection" {
        It "Should not include auto-detection when ResponseType is Text" {
            $prompt = Invoke-LLM "test" -ResponseType Text -GetPrompt
            $prompt | Should -Not -Match "REQUEST FOR INFORMATION"
            $prompt | Should -Match "TEXT format"
        }
        
        It "Should not include auto-detection when ResponseType is Data" {
            $prompt = Invoke-LLM "test" -ResponseType Data -GetPrompt
            $prompt | Should -Not -Match "REQUEST FOR DATA"
            $prompt | Should -Match "JSON format"
        }
        
        It "Should not include auto-detection when ResponseType is Script" {
            $prompt = Invoke-LLM "test" -ResponseType Script -GetPrompt
            $prompt | Should -Not -Match "REQUEST TO ACCOMPLISH A TASK"
            $prompt | Should -Match "PowerShell script"
        }
    }
}

Describe "Response Format Instructions" {
    Context "When testing format instructions content" {
        It "Should instruct LLM to respond in clear TEXT for information" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "clear TEXT format"
        }
        
        It "Should instruct LLM about format explicitly requested by user" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "format explicitly requested by the user"
        }
        
        It "Should mention CSV, JSON, XML as examples" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "CSV"
            $prompt | Should -Match "JSON"
            $prompt | Should -Match "XML"
        }
        
        It "Should mention system administration examples" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "listing processes"
            $prompt | Should -Match "checking ports"
            $prompt | Should -Match "managing files"
        }
        
        It "Should mention registry operations for Windows context" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "registry operations"
        }
        
        It "Should mention services and network connections" {
            $prompt = Invoke-LLM "test" -GetPrompt
            $prompt | Should -Match "services"
            $prompt | Should -Match "network connections"
        }
    }
}

Describe "Integration Test Scenarios" {
    Context "When simulating real-world prompts" {
        It "Should handle question prompts" {
            $prompts = @(
                "What is PowerShell?",
                "How do I use Get-Process?",
                "Explain the difference between Get-Item and Get-ChildItem"
            )
            
            foreach ($testPrompt in $prompts) {
                $result = Invoke-LLM $testPrompt -GetPrompt
                $result | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should handle data request prompts" {
            $prompts = @(
                "List 10 common PowerShell cmdlets",
                "Give me 5 examples of file extensions",
                "Show me a list of HTTP status codes"
            )
            
            foreach ($testPrompt in $prompts) {
                $result = Invoke-LLM $testPrompt -GetPrompt
                $result | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should handle task/action prompts" {
            $prompts = @(
                "Get all processes consuming more than 100MB",
                "List all files in the current directory",
                "Check if port 8080 is in use",
                "Show disk space usage"
            )
            
            foreach ($testPrompt in $prompts) {
                $result = Invoke-LLM $testPrompt -GetPrompt
                $result | Should -Match "PowerShell script"
            }
        }
        
        It "Should handle ambiguous prompts with auto-detection" {
            $ambiguousPrompts = @(
                "PowerShell processes",
                "files",
                "network"
            )
            
            foreach ($testPrompt in $ambiguousPrompts) {
                $result = Invoke-LLM $testPrompt -GetPrompt
                # Should include all three options for LLM to decide
                $result | Should -Match "REQUEST FOR"
            }
        }
    }
}
