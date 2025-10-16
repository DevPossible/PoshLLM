# PoshLLM

A connector that brings LLMs to the PowerShell REPL command line

## Description
Brings LLM power to the REPL command line

## Author
DevPossible LLC

## License
MIT

## Module Structure

This module follows standard PowerShell module conventions with the following structure:
- `PoshLLM.psd1` - Module manifest file
- `PoshLLM.psm1` - Main module script file
- `Source/Public/` - Directory containing public functions
- `Source/Private/` - Directory containing private functions (if any)
- `Tests/` - Directory containing test scripts

## Installation

To install this module, you can either:
1. Copy the module files to your PowerShell Modules directory
2. Use PowerShellGet to install from the PowerShell Gallery (once published)

## Usage

Import the module using:
```powershell
Import-Module PoshLLM
```

### Configuration

Before using the module, you need to configure it with your LLM system details:
```powershell
Set-PoshLLMConfiguration -LLMSystem "ollama" -Model "llama2" -URL "http://localhost:11434"
```

The module comes with default values:
- LLM System: ollama
- Model: qwen3:8b
- URL: http://localhost:11434
- Context Size: 4096

You can simply run `Set-PoshLLMConfiguration` to use these defaults, or specify custom values as needed.

For backward compatibility, the alias `Configure-PoshLLM` is also available.

### Available Functions

- `Get-PoshLLMInfo` - Gets information about the PoshLLM module
- `Invoke-LLM` - Sends input to an LLM and processes the response
- `Set-PoshLLMConfiguration` - Configures the LLM connection details (alias: `Configure-PoshLLM`)
- `Show-SyntaxHighlightedCode` - Displays PowerShell code with syntax highlighting

### Invoke-LLM Function

The `Invoke-LLM` function takes any input and sends it to an LLM system. If the LLM returns information, it is displayed. If it returns code, the user is prompted to either execute it, copy it to the clipboard, or exit without action.

The function accepts optional parameters that can override the configured values:
- `-LLMSystem` - Override the configured LLM system
- `-Model` - Override the configured model
- `-URL` - Override the configured URL
- `-ContextSize` - Override the configured context size

Example usage:
```powershell
Invoke-LLM "What is PowerShell?"
Invoke-LLM "Write a function to list files"
Invoke-LLM -Prompt "Write a function to list files" -Model "llama3:latest"

# Or use convenient short aliases:
ai "What is PowerShell?"
llm "list running processes"
ask "how do I compress files in PowerShell?"
```

### Available Aliases

The module provides three convenient short aliases for `Invoke-LLM`:
- `ai` - Short for AI interaction
- `llm` - Short for LLM (Large Language Model)
- `ask` - Intuitive for asking questions

These aliases make it faster to interact with the LLM from the command line.

## Contributing
Contributions are welcome! Please fork the repository and submit pull requests.

## License
MIT License
