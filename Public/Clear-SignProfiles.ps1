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
    
    foreach ($profile in $externalProfiles) {
        $profileName = $profile.Key
        $profilePath = $profile.Value.path
        
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
