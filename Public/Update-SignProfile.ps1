function Update-SignProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName
    )

    $config = Get-Config
    if (-not $config.profiles.ContainsKey($ProfileName)) {
        throw "Profile '$ProfileName' not found"
    }

    $profilePath = $config.profiles[$ProfileName].path
    $profileData = Get-Content $profilePath | ConvertFrom-Json -AsHashtable
    $updateMade = $false

    if ($profileData.type -eq 'local') {
        $updateSecret = Read-Host "Update certificate password? (y/n)"
        if ($updateSecret -eq 'y') {
            $securePassword = Read-Host "Enter new certificate password" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -ProfilePath $profilePath -InputAlias "pwd" -SecureInput $securePassword
            $updateMade = $true
        }
    }
    else {
        $updateSecret = Read-Host "Update client secret? (y/n)"
        if ($updateSecret -eq 'y') {
            $secureSecret = Read-Host "Enter new client secret" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -ProfilePath $profilePath -InputAlias "kvs" -SecureInput $secureSecret
            $updateMade = $true
        }
    }
    
    $updateParams = Read-Host "Update additional parameters? (y/n)"
    if ($updateParams -eq 'y') {
        $currentParams = if ($profileData.ContainsKey('additionalParams')) { $profileData.additionalParams } else { "" }
        Write-Host "Current additional parameters: $currentParams"
        $additionalParams = Read-Host "Enter new additional parameters (leave empty to remove)"
        
        if ([string]::IsNullOrWhiteSpace($additionalParams)) {
            if ($profileData.ContainsKey('additionalParams')) {
                $profileData.Remove('additionalParams')
                $updateMade = $true
            }
        }
        else {
            $profileData.additionalParams = $additionalParams
            $updateMade = $true
        }
    }
    
    if ($updateMade) {
        $profileData | ConvertTo-Json | Set-Content $profilePath
        Write-Host "Profile '$ProfileName' updated successfully"
    }
    else {
        Write-Host "No changes made to profile '$ProfileName'"
    }
}
