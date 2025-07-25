<#
.SYNOPSIS
    Removes a code signing profile from the SignModule configuration.

.DESCRIPTION
    The Remove-SignProfile function removes a specified code signing profile from the SignModule
    configuration. By default, it will remove the profile entry from the configuration but will
    only delete the actual profile file if it's located in the default profiles directory or
    if the -RemoveFile parameter is specified.

    This function provides a way to clean up unused or obsolete signing profiles from your
    system. Related secure files associated with the profile will also be removed when the
    profile file is deleted.

.PARAMETER ProfileName
    The name of the signing profile to remove. This parameter is mandatory and must match
    an existing profile name in the configuration.

.PARAMETER RemoveFile
    A switch parameter that forces removal of the profile file even if it's located outside
    the default profiles directory. By default, profile files outside the profiles directory
    are not deleted unless this parameter is specified.

.EXAMPLE
    Remove-SignProfile -ProfileName 'MyLocalCertProfile'

    Removes the profile named 'MyLocalCertProfile' from the configuration. If the profile file
    is in the default profiles directory, it will also be deleted along with any associated
    secure files.

.EXAMPLE
    Remove-SignProfile -ProfileName 'ExternalProfile' -RemoveFile

    Removes the profile named 'ExternalProfile' from the configuration and deletes the profile
    file and associated secure files regardless of their location.

.NOTES
    File Name      : Remove-SignProfile.ps1
    Author         : GrafGenerator
    Prerequisite   : PowerShell 5.1 or later
    Copyright 2025 : GrafGenerator

    This function will throw an error if the specified profile does not exist in the configuration.

    Profile files located in the default profiles directory (%PSModulePath%\SignModule\Profiles)
    are always deleted, while profile files outside this directory are only deleted when the
    -RemoveFile switch is used.

.LINK
    Add-SignProfile

.LINK
    Update-SignProfile

.LINK
    Clear-SignProfiles

.LINK
    https://github.com/GrafGenerator/pwsh-sign-module
#>
function Remove-SignProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter()]
        [switch]$RemoveFile
    )

    Test-ProfileName -ProfileName $ProfileName

    $config = Get-Config
    if (-not $config.profiles.ContainsKey($ProfileName)) {
        throw "Profile '$ProfileName' not found"
    }

    $profileFile = [FileInfo]::new($config.profiles[$ProfileName].path)
    $profilesDirectoryPath = (Get-Item $script:PROFILES_DIR).FullName;

    $config.profiles.Remove($ProfileName)
    Save-Config $config

    $isInProfilesDir = $profileFile.FullName.StartsWith($profilesDirectoryPath)
    if ($isInProfilesDir -or $RemoveFile) {
        $profileFile.Delete();

        # Remove secure input files
        Get-ChildItem $profileFile.Directory.FullName -Filter "$ProfileName-*" | Remove-Item -Force
    } else {
        Write-Output "Skipping removal of profile file at '$profilePath' as it is outside the profiles directory. Use -RemoveFile to force removal."
    }
}
