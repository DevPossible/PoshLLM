# PoshLLM Module
# Brings LLM power to the REPL command line

# This is the main module file for PoshLLM
# Author: DevPossible LLC
# Description: Brings LLM power to the REPL command line

# Import public functions
. "$PSScriptRoot\Public\Get-PoshLLMInfo.ps1"
. "$PSScriptRoot\Public\Invoke-LLM.ps1"
. "$PSScriptRoot\Public\Configure-PoshLLM.ps1"
. "$PSScriptRoot\Public\Show-SyntaxHighlightedCode.ps1"

# Export all public functions and aliases
Export-ModuleMember -Function * -Alias *
