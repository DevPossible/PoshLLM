function Get-PoshLLMInfo {
    <#
    .SYNOPSIS
        Gets information about the PoshLLM module
    .DESCRIPTION
        Provides basic information about the PoshLLM module including version and description
    .EXAMPLE
        Get-PoshLLMInfo
    #>
    [CmdletBinding()]
    param()
    
    $module = Get-Module -Name PoshLLM
    if ($module) {
        [PSCustomObject]@{
            Name = $module.Name
            Version = $module.Version
            Description = $module.Description
            Author = $module.Author
        }
    }
    else {
        Write-Error "PoshLLM module is not loaded"
    }
}
