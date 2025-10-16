# PoshLLM

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PoshLLM?label=PowerShell%20Gallery&logo=powershell)](https://www.powershellgallery.com/packages/PoshLLM)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PoshLLM?label=Downloads)](https://www.powershellgallery.com/packages/PoshLLM)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/DevPossible/PoshLLM/publish-to-psgallery.yml?label=Build)](https://github.com/DevPossible/PoshLLM/actions)

**PoshLLM** brings the power of Large Language Models (LLMs) directly to your PowerShell REPL command line. Interact with local LLM systems like Ollama seamlessly from your PowerShell session with intuitive commands and convenient aliases.

## ✨ Features

- 🚀 **Direct LLM Integration** - Connect to local LLM systems (Ollama) from PowerShell
- 💬 **Interactive Prompting** - Ask questions and get intelligent responses instantly
- 🔧 **Code Generation** - Generate PowerShell code with LLM assistance
- ⚡ **Quick Aliases** - Use `ai`, `llm`, or `ask` for fast interaction
- 🎨 **Syntax Highlighting** - Beautiful PowerShell code highlighting in responses
- 🔄 **Code Execution** - Option to execute generated code directly or copy to clipboard
- ⚙️ **Flexible Configuration** - Configure LLM system, model, URL, and context size
- 🎯 **Parameter Overrides** - Override settings per command as needed

## 📋 Requirements

- **PowerShell 7.0 or later**
- **Local LLM System** (currently supports [Ollama](https://ollama.ai/))
- **Windows, macOS, or Linux**

## 🚀 Installation

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name PoshLLM -Scope CurrentUser
```

### From Source

```powershell
git clone https://github.com/DevPossible/PoshLLM.git
cd PoshLLM
Import-Module ./PoshLLM.psd1
```

## 🎯 Quick Start

### 1. Import the Module

```powershell
Import-Module PoshLLM
```

### 2. Configure Your LLM Connection

```powershell
# Use defaults (Ollama on localhost:11434 with qwen3:8b model)
Set-PoshLLMConfiguration

# Or specify custom settings
Set-PoshLLMConfiguration -LLMSystem "ollama" -Model "llama3:latest" -URL "http://localhost:11434"
```

### 3. Start Using LLMs in PowerShell!

```powershell
# Ask a question
ai "What is PowerShell?"

# Get code generation help
llm "Write a function to compress files in a directory"

# Use the ask alias for natural queries
ask "How do I list running processes sorted by memory usage?"
```

## 📖 Usage Guide

### Configuration

The module comes with sensible defaults:
- **LLM System**: ollama
- **Model**: qwen3:8b
- **URL**: http://localhost:11434
- **Context Size**: 4096

Configure once and use throughout your session:

```powershell
# Minimal configuration (uses defaults)
Set-PoshLLMConfiguration

# Full configuration
Set-PoshLLMConfiguration -LLMSystem "ollama" `
                         -Model "mistral:latest" `
                         -URL "http://localhost:11434" `
                         -ContextSize 8192

# Using the backward-compatible alias
Configure-PoshLLM -Model "llama3:8b"
```

### Asking Questions

```powershell
# General questions
ai "Explain what .NET assemblies are"

# PowerShell-specific help
llm "How do I parse JSON in PowerShell?"

# Command suggestions
ask "What's the best way to handle errors in PowerShell scripts?"
```

### Understanding Command Errors with Context

Use `-IncludeContext` to help the LLM understand what went wrong:

```powershell
PS C:\> git clone bob
fatal: repository 'bob' does not exist

PS C:\> ai "why did this command fail" -IncludeContext 2 -ResponseType Text
LLM Response:
The command `git clone bob` failed because the `git clone` command requires 
a valid repository URL or path to clone from. The argument `bob` is not a 
valid URL or existing repository path.

To fix this, provide a valid Git repository URL or a local path to a repository.
```

This example shows how PoshLLM can analyze your recent command history to provide context-aware explanations.

### Code Generation

When PoshLLM detects code in the response, you'll be prompted with options:

```powershell
llm "Write a function to list all running services"

# You'll see highlighted code and options to:
# [E] Execute - Run the code immediately
# [C] Copy - Copy to clipboard
# [X] Exit - Just display without action
```

### Override Configuration Per Command

```powershell
# Use a different model for one query
Invoke-LLM -Prompt "Explain recursion" -Model "codellama:latest"

# Use different URL temporarily
Invoke-LLM -Prompt "Write a Get function" -URL "http://remote-llm:11434"

# Override multiple parameters
Invoke-LLM -Prompt "Complex query" -Model "llama3:70b" -ContextSize 16384
```

### Available Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Invoke-LLM` | `ai`, `llm`, `ask` | Send prompts to the LLM and process responses |
| `Set-PoshLLMConfiguration` | `Configure-PoshLLM` | Configure LLM connection settings |
| `Get-PoshLLMInfo` | - | Display module information and current configuration |
| `Show-SyntaxHighlightedCode` | - | Display PowerShell code with syntax highlighting |

## 🔧 Advanced Usage

### Using in Scripts

```powershell
# Example: Generate and execute code dynamically
$code = ai "Create a function Get-LargeFiles that finds files over 100MB" -Raw
Invoke-Expression $code
Get-LargeFiles -Path "C:\Users"
```

### Custom Prompts with Context

```powershell
# Multi-line prompts
$prompt = @"
I need a PowerShell function that:
1. Accepts a directory path
2. Recursively searches for .log files
3. Filters files older than 30 days
4. Returns file objects with size and age
"@

llm $prompt
```

### Integrating with Workflows

```powershell
# Add to your PowerShell profile for instant access
if (Get-Module -ListAvailable -Name PoshLLM) {
    Import-Module PoshLLM
    Set-PoshLLMConfiguration -Model "codellama:latest"
}
```

## 🛠️ Setting Up Ollama

PoshLLM works with [Ollama](https://ollama.ai/), a local LLM runtime.

### Install Ollama

1. Download from [ollama.ai](https://ollama.ai/)
2. Install following platform-specific instructions
3. Pull a model:
   ```bash
   ollama pull llama3:latest
   ollama pull codellama:latest
   ollama pull qwen3:8b
   ```
4. Verify it's running:
   ```bash
   ollama list
   ```

### Recommended Models for PowerShell

- **codellama** - Best for code generation
- **llama3** - Great all-around model
- **qwen3** - Fast and efficient
- **mistral** - Good balance of speed and capability

## ❓ FAQ

### Q: Can I use models other than Ollama?
A: Currently, PoshLLM is designed for Ollama. Support for other LLM systems (OpenAI, Azure OpenAI, etc.) may be added in future versions.

### Q: Is my data sent to the cloud?
A: When using Ollama, PoshLLM connects to your Ollama instance. All processing happens on your instance.

### Q: Can I use this in production scripts?
A: While PoshLLM is great for development and learning, be cautious with executing generated code in production without review. That's a nice way of saying absolutely not :)

### Q: Why does code execution require confirmation?
A: For security. PoshLLM always prompts before executing generated code to prevent accidental execution of potentially harmful commands.

### Q: Can I change models mid-session?
A: Yes! Use `Set-PoshLLMConfiguration -Model "newmodel"` or override per-command with the `-Model` parameter.

### Q: Does it work with PowerShell 5.1?
A: No, PoshLLM requires PowerShell 7.0 or later for optimal performance and modern features.

## 🐛 Troubleshooting

### Connection Refused Error

```powershell
# Verify Ollama is running
ollama list

# Check if the service is accessible
Test-NetConnection -ComputerName localhost -Port 11434

# Restart Ollama if needed
```

### Model Not Found

```powershell
# List available models
ollama list

# Pull the model you want to use
ollama pull llama3:latest

# Update PoshLLM configuration
Set-PoshLLMConfiguration -Model "llama3:latest"
```

### Slow Responses

- Use smaller models (e.g., `qwen3:8b` instead of `llama3:70b`)
- Reduce context size: `Set-PoshLLMConfiguration -ContextSize 2048`
- Ensure Ollama has sufficient system resources

### Module Not Found

```powershell
# Check if installed
Get-Module -ListAvailable PoshLLM

# Install if missing
Install-Module -Name PoshLLM -Scope CurrentUser -Force

# Import explicitly
Import-Module PoshLLM -Force
```

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Make your changes** and test thoroughly
4. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
5. **Push to the branch** (`git push origin feature/AmazingFeature`)
6. **Open a Pull Request**

### Development Setup

```powershell
# Clone the repository
git clone https://github.com/DevPossible/PoshLLM.git
cd PoshLLM

# Run tests
Invoke-Pester -Path ./Tests/

# Test the module locally
Import-Module ./PoshLLM.psd1 -Force
```

Please ensure:
- Code follows PowerShell best practices
- All tests pass
- New features include tests
- Documentation is updated

## 🗺️ Roadmap

- [ ] Support for additional LLM providers (OpenAI, Azure OpenAI, Anthropic)
- [ ] Conversation history and context management
- [ ] Custom system prompts and personas
- [ ] Response caching for repeated queries
- [ ] Export/import conversation sessions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Built with ❤️ by [DevPossible LLC](https://github.com/DevPossible)
- Powered by [Ollama](https://ollama.ai/)
- Inspired by the PowerShell and AI communities

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/DevPossible/PoshLLM/issues)
- **Discussions**: [GitHub Discussions](https://github.com/DevPossible/PoshLLM/discussions)
- **Documentation**: [Wiki](https://github.com/DevPossible/PoshLLM/wiki) (coming soon)

## 🌟 Show Your Support

If you find PoshLLM useful, please:
- ⭐ Star the repository
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📢 Share with others

---

**Made with PowerShell and AI** | Copyright © 2025 DevPossible LLC
