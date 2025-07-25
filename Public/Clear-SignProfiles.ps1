<#
.SYNOPSIS
    Removes all code signing profiles from the SignModule configuration.

.DESCRIPTION
    The Clear-SignProfiles function removes all signing profiles from the SignModule
    configuration. By default, it will:
    - Clear all profiles from the configuration
    - Delete all profile files in the default profiles directory
    - Keep external profile files (outside the default profiles directory) intact

    When the -RemoveFile switch is specified, all profile files will be deleted,
    including those outside the default profiles directory.
    
    This function is useful for resetting the SignModule to a clean state or for
    performing a complete reconfiguration of all signing profiles.

.PARAMETER RemoveFile
    A switch parameter that, when specified, forces the deletion of all profile files,
    including those located outside the default profiles directory. By default,
    external profile files are not deleted unless this parameter is specified.

.EXAMPLE
    Clear-SignProfiles
    
    Removes all profiles from the configuration and deletes all profile files in the
    default profiles directory. External profile files are not deleted.

.EXAMPLE
    Clear-SignProfiles -RemoveFile
    
    Removes all profiles from the configuration and deletes all profile files,
    including those outside the default profiles directory.

.NOTES
    File Name      : Clear-SignProfiles.ps1
    Author         : GrafGenerator
    Prerequisite   : PowerShell 5.1 or later
    Copyright 2025 : GrafGenerator
    
    This function will remove all profile entries from the configuration. By default,
    only profile files in the default profiles directory (%PSModulePath%\SignModule\Profiles)
    are deleted. Use the -RemoveFile switch to delete all profile files regardless of location.
    
    Related secure files associated with the profiles will also be removed when
    the profile files are deleted.

.LINK
    Add-SignProfile

.LINK
    Remove-SignProfile

.LINK
    Update-SignProfile

.LINK
    https://github.com/GrafGenerator/pwsh-sign-module
#>
function Clear-SignProfiles {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$RemoveFile
    )

    $config = Get-Config
    
    $profilesDirectoryPath = (Get-Item $script:PROFILES_DIR).FullName;

    # Handle profiles outside of profiles directory first
    $externalProfiles = $config.profiles.GetEnumerator() | Where-Object { -not (Get-Item $_.Value.path).FullName.StartsWith($profilesDirectoryPath) }
    $externalProfileNames = @()
    
    foreach ($profileData in $externalProfiles) {
        $profileName = $profileData.Key
        $profilePath = $profileData.Value.path
        
        if ($RemoveFile) {
            $profileFile = Get-Item $profilePath
            
            $profileFile.Delete();

            # Remove secure input files
            Get-ChildItem $profileFile.Directory.FullName -Filter "$profileName-*" | Remove-Item -Force
        } else {
            Write-Output "Skipping removal of external profile file at '$profilePath'. Use -RemoveFile to force removal."
            # Store profile names that should be preserved
            $externalProfileNames += $profileName
        }
    }

    # Always clean up profiles directory
    Get-ChildItem $script:PROFILES_DIR -File | Remove-Item -Force

    # Create a new profiles hashtable
    $newProfiles = @{}
    
    # If not removing external profiles, preserve them in the config
    if (-not $RemoveFile -and $externalProfileNames.Count -gt 0) {
        foreach ($name in $externalProfileNames) {
            $newProfiles[$name] = $config.profiles[$name]
        }
    }
    
    # Update the configuration
    $config.profiles = $newProfiles
    Save-Config $config
}
