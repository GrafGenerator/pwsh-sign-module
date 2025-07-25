<#
.SYNOPSIS
Creates a new code signing profile for use with SignModule.

.DESCRIPTION
The Add-SignProfile function creates a new signing profile that can be used to sign executable files.
Profiles can be created interactively (by providing configuration details through prompts) or by
importing an existing profile JSON file. Profiles support both local certificate signing and
Azure Key Vault integration.

.PARAMETER ProfileName
Specifies the name for the new signing profile. This name will be used to reference the profile
in other SignModule commands. Profile names must be unique and cannot contain invalid characters.

.PARAMETER ProfilePath
Optional path to an existing profile JSON file to import. If not specified, the function will
prompt for profile configuration details interactively. The JSON file should contain the
profile configuration in the expected format.

.INPUTS
None. You cannot pipe objects to Add-SignProfile.

.OUTPUTS
None. This function does not return any objects.

.EXAMPLE
Add-SignProfile -ProfileName "Production"

Creates a new profile named "Production" using interactive prompts to configure the signing details.
You will be prompted to specify whether this is a local certificate or Azure Key Vault profile,
and then provide the necessary configuration details.

.EXAMPLE
Add-SignProfile -ProfileName "Staging" -ProfilePath "C:\Certs\staging-profile.json"

Creates a new profile named "Staging" by importing configuration from an existing JSON file.
The JSON file should contain the profile configuration in the expected format.

.EXAMPLE
Add-SignProfile -ProfileName "LocalCert"
# When prompted, select 'local' type and provide:
# - Signing tool path: C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe
# - Certificate path: C:\Certificates\MyCert.pfx
# - Certificate password: (entered securely)
# - Timestamp URL: http://timestamp.digicert.com

Example of creating a local certificate profile with typical Windows SDK paths.

.EXAMPLE
Add-SignProfile -ProfileName "AzureKV"
# When prompted, select 'azure' type and provide:
# - Azure SignTool path: C:\Tools\azuresigntool.exe
# - Key Vault URL: https://myvault.vault.azure.net/
# - Tenant ID: 12345678-1234-1234-1234-123456789012
# - Client ID: 87654321-4321-4321-4321-210987654321
# - Client Secret: (entered securely)
# - Certificate Name: CodeSigningCert

Example of creating an Azure Key Vault profile for cloud-based signing.

.NOTES
File Name      : Add-SignProfile.ps1
Author         : GrafGenerator
Prerequisite   : PowerShell 5.1 or later
Copyright 2025 : GrafGenerator

Profile configuration files are stored in %PSModulePath%\SignModule\profiles\ and contain
non-sensitive configuration data only. Sensitive information like passwords and secrets
are stored separately using PowerShell SecureString encryption.

.LINK
Update-SignProfile

.LINK
Remove-SignProfile

.LINK
Export-SignedExecutable

.LINK
https://github.com/GrafGenerator/pwsh-sign-module
#>
function Add-SignProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter()]
        [string]$ProfilePath
    )

    Initialize-ModuleConfig
    $config = Get-Config

    Test-ProfileName -ProfileName $ProfileName

    if ($config.profiles.ContainsKey($ProfileName)) {
        throw "Profile '$ProfileName' already exists"
    }

    if (-not $ProfilePath) {
        $profileType = Read-Host "Enter profile type (local/azure)"
        if ($profileType -notin @('local', 'azure')) {
            throw "Invalid profile type. Must be 'local' or 'azure'"
        }

        $targetProfilePath = Join-Path $script:PROFILES_DIR "$ProfileName.json"

        $profileData = @{
            type = $profileType
        }

        if ($profileType -eq 'local') {
            $profileData.signToolPath = Read-Host "Enter path to local sign tool installation"
            $profileData.certificatePath = Read-Host "Enter path to local certificate"
            
            $securePassword = Read-Host "Enter certificate password" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -ProfilePath $targetProfilePath -InputAlias "pwd" -SecureInput $securePassword
            
            $additionalParams = Read-Host "Enter additional parameters for sign tool (e.g., '/tr http://timestamp.server' - optional)"
            if (-not [string]::IsNullOrWhiteSpace($additionalParams)) {
                $profileData.additionalParams = $additionalParams
            }
        }
        else {
            $profileData.signToolPath = Read-Host "Enter path to azure sign tool installation"
            $profileData.keyVaultUrl = Read-Host "Enter key vault URL"
            $profileData.tenantId = Read-Host "Enter tenant ID"
            $profileData.clientId = Read-Host "Enter client ID"
            $profileData.certificateName = Read-Host "Enter certificate name"

            $secureSecret = Read-Host "Enter client secret" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -ProfilePath $targetProfilePath -InputAlias "kvs" -SecureInput $secureSecret
            
            $additionalParams = Read-Host "Enter additional parameters for sign tool (e.g., '-tr http://timestamp.server' - optional)"
            if (-not [string]::IsNullOrWhiteSpace($additionalParams)) {
                $profileData.additionalParams = $additionalParams
            }
        }

        $profileData | ConvertTo-Json | Set-Content $targetProfilePath
    }
    else {
        $targetProfilePath = [FileInfo]::new($ProfilePath).FullName

        if (-not (Test-Path $targetProfilePath)) {
            throw "Profile file not found at path: $targetProfilePath"
        }
    }

    $config.profiles[$ProfileName] = @{
        path = $targetProfilePath
    }

    Save-Config $config
}
