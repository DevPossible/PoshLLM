@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Source\PoshLLM.psm1'

    # Version number of this module.
    ModuleVersion = '0.3.1'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = '9f8e3a4b-7c5d-4e2f-a1b8-3d6c9e7f2a5b'

    # Author of this module
    Author = 'DevPossible LLC'

    # Company or vendor of this module
    CompanyName = 'DevPossible LLC'

    # Copyright statement for this module
    Copyright = 'Copyright (c) 2025 DevPossible LLC. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Brings LLM (Large Language Model) power to the PowerShell REPL command line. Interact with local LLM systems like Ollama directly from your PowerShell session with convenient commands and aliases.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @('Source\PoshLLM.psm1')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Get-PoshLLMInfo', 'Invoke-LLM', 'Set-PoshLLMConfiguration', 'Get-PoshLLMConfig', 'Show-SyntaxHighlightedCode')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @('Configure-PoshLLM', 'ai', 'llm', 'ask')

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList = @('Source\PoshLLM.psm1')

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('LLM', 'AI', 'Ollama', 'MachineLearning', 'ChatBot', 'PowerShell', 'REPL', 'CommandLine', 'Automation', 'PSEdition_Core')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/DevPossible/PoshLLM/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/DevPossible/PoshLLM'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of PoshLLM module. Features include:
- Integration with local LLM systems (Ollama)
- Interactive prompt with code execution capabilities
- Syntax highlighting for PowerShell code
- Convenient aliases (ai, llm, ask) for quick access
- Configurable LLM settings
- Support for multiple models and endpoints'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
