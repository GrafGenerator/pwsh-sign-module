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
