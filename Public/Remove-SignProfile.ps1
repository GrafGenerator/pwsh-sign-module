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
