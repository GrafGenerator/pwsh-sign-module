<#
.SYNOPSIS
Updates secure inputs (passwords/secrets) for an existing signing profile.

.DESCRIPTION
The Update-SignProfile function allows you to update sensitive information for an existing
signing profile, such as certificate passwords for local profiles or client secrets for
Azure Key Vault profiles. This is useful when passwords expire or need to be rotated
for security purposes. The function maintains the existing profile configuration while
only updating the secure credentials.

.PARAMETER ProfileName
Specifies the name of an existing signing profile to update. The profile must exist
in the configuration. Use Add-SignProfile to create new profiles.

.INPUTS
None. You cannot pipe objects to Update-SignProfile.

.OUTPUTS
None. This function does not return any objects.

.EXAMPLE
Update-SignProfile -ProfileName "Production"

Updates the secure credentials for the "Production" profile. For local certificate profiles,
you will be prompted to enter a new certificate password. For Azure Key Vault profiles,
you will be prompted to enter a new client secret.

.EXAMPLE
Update-SignProfile -ProfileName "LocalCert"
# Prompts for new certificate password
# Password is securely stored using PowerShell SecureString

Example of updating a local certificate profile's password.

.EXAMPLE
Update-SignProfile -ProfileName "AzureKV"
# Prompts for new client secret
# Secret is securely stored using PowerShell SecureString

Example of updating an Azure Key Vault profile's client secret.

.NOTES
File Name      : Update-SignProfile.ps1
Author         : GrafGenerator
Prerequisite   : PowerShell 5.1 or later
Copyright 2025 : GrafGenerator

This function only updates sensitive credentials (passwords/secrets) and does not
modify other profile configuration settings. To change non-sensitive settings like
paths or URLs, you need to remove and recreate the profile.

Sensitive information is stored using PowerShell SecureString encryption and is
protected by Windows Data Protection API (DPAPI).

.LINK
Add-SignProfile

.LINK
Remove-SignProfile

.LINK
Export-SignedExecutable

.LINK
https://github.com/GrafGenerator/pwsh-sign-module
#>
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
