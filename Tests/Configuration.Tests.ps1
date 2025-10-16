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

Describe "Configuration Management" {
    Context "When saving valid configuration" {
        It "Should save configuration successfully" {
            Set-PoshLLMConfiguration -Model "test-model" -URL "http://localhost:11434"
            $config = Get-PoshLLMConfig
            $config.Model | Should -Be "test-model"
            $config.URL | Should -Be "http://localhost:11434"
        }
        
        It "Should use default values for optional parameters" {
            Set-PoshLLMConfiguration
            $config = Get-PoshLLMConfig
            $config.LLMSystem | Should -Be "ollama"
            $config.Model | Should -Be "qwen3:8b"
            $config.URL | Should -Be "http://localhost:11434"
            $config.ContextSize | Should -Be 4096
        }
        
        It "Should create config directory if it doesn't exist" {
            $configDir = Split-Path $script:configPath -Parent
            if (Test-Path $configDir) {
                Remove-Item $configDir -Recurse -Force
            }
            
            Set-PoshLLMConfiguration -Model "test-model"
            Test-Path $configDir | Should -Be $true
        }
    }
    
    Context "When reading configuration" {
        BeforeEach {
            Set-PoshLLMConfiguration -Model "test-model" -URL "http://test:1234" -ContextSize 8192
        }
        
        It "Should retrieve saved configuration" {
            $config = Get-PoshLLMConfig
            $config | Should -Not -BeNullOrEmpty
            $config.Model | Should -Be "test-model"
            $config.URL | Should -Be "http://test:1234"
            $config.ContextSize | Should -Be 8192
        }
        
        It "Should return hashtable type" {
            $config = Get-PoshLLMConfig
            $config.GetType().Name | Should -Be "Hashtable"
        }
        
        It "Should return null when config doesn't exist" {
            Remove-Item $script:configPath -Force
            $config = Get-PoshLLMConfig
            $config | Should -BeNullOrEmpty
        }
    }
    
    Context "When validating context size" {
        It "Should accept valid context size within range" {
            { Set-PoshLLMConfiguration -ContextSize 4096 } | Should -Not -Throw
            { Set-PoshLLMConfiguration -ContextSize 65536 } | Should -Not -Throw
            { Set-PoshLLMConfiguration -ContextSize 1 } | Should -Not -Throw
        }
        
        It "Should reject context size exceeding 64KB (65536 bytes)" {
            { Set-PoshLLMConfiguration -ContextSize 70000 } | Should -Throw
        }
        
        It "Should reject context size of 0 or negative" {
            { Set-PoshLLMConfiguration -ContextSize 0 } | Should -Throw
            { Set-PoshLLMConfiguration -ContextSize -1 } | Should -Throw
        }
        
        It "Should reject context size exactly at 65537 (just over limit)" {
            { Set-PoshLLMConfiguration -ContextSize 65537 } | Should -Throw
        }
    }
    
    Context "When handling invalid configuration" {
        It "Should handle corrupted config file gracefully" {
            # Create invalid JSON
            "{ invalid json }" | Out-File -FilePath $script:configPath -Encoding UTF8
            
            $config = Get-PoshLLMConfig
            $config | Should -BeNullOrEmpty
        }
    }
}
