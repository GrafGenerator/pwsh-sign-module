using namespace System.Security

# Module variables
$script:CONFIG_FILE = Join-Path $PSScriptRoot "config.json"
$script:PROFILES_DIR = Join-Path $PSScriptRoot "profiles"

# Helper functions
function Initialize-ModuleConfig {
    if (-not (Test-Path $script:CONFIG_FILE)) {
        @{ profiles = @{} } | ConvertTo-Json | Set-Content $script:CONFIG_FILE
    }
    if (-not (Test-Path $script:PROFILES_DIR)) {
        New-Item -ItemType Directory -Path $script:PROFILES_DIR | Out-Null
    }
}

function Get-Config {
    if (Test-Path $script:CONFIG_FILE) {
        Get-Content $script:CONFIG_FILE | ConvertFrom-Json -AsHashtable
    }
    else {
        @{ profiles = @{} }
    }
}

function Save-Config {
    param($Config)
    $Config | ConvertTo-Json | Set-Content $script:CONFIG_FILE
}

function Save-SecureInput {
    param(
        [string]$ProfileName,
        [string]$InputAlias,
        [SecureString]$SecureInput
    )
    $secureFilePath = Join-Path $script:PROFILES_DIR "$ProfileName-$InputAlias"
    $SecureInput | ConvertFrom-SecureString | Set-Content $secureFilePath
}

function Get-SecureInput {
    param(
        [string]$ProfileName,
        [string]$InputAlias
    )
    $secureFilePath = Join-Path $script:PROFILES_DIR "$ProfileName-$InputAlias"
    if (Test-Path $secureFilePath) {
        Get-Content $secureFilePath | ConvertTo-SecureString
    }
}

# Exported functions
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

    if ($config.profiles.ContainsKey($ProfileName)) {
        throw "Profile '$ProfileName' already exists"
    }

    if (-not $ProfilePath) {
        $profileType = Read-Host "Enter profile type (local/azure)"
        if ($profileType -notin @('local', 'azure')) {
            throw "Invalid profile type. Must be 'local' or 'azure'"
        }

        $profileData = @{
            type = $profileType
        }

        if ($profileType -eq 'local') {
            $profileData.signToolPath = Read-Host "Enter path to local sign tool installation"
            $profileData.certificatePath = Read-Host "Enter path to local certificate"
            $securePassword = Read-Host "Enter certificate password" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -InputAlias "pwd" -SecureInput $securePassword
        }
        else {
            $profileData.signToolPath = Read-Host "Enter path to azure sign tool installation"
            $profileData.keyVaultUrl = Read-Host "Enter key vault URL"
            $profileData.tenantId = Read-Host "Enter tenant ID"
            $profileData.clientId = Read-Host "Enter client ID"
            $secureSecret = Read-Host "Enter client secret" -AsSecureString
            $profileData.certificateName = Read-Host "Enter certificate name"
            Save-SecureInput -ProfileName $ProfileName -InputAlias "kvs" -SecureInput $secureSecret
        }

        $ProfilePath = Join-Path $script:PROFILES_DIR "$ProfileName.json"
        $profileData | ConvertTo-Json | Set-Content $ProfilePath
    }
    else {
        if (-not (Test-Path $ProfilePath)) {
            throw "Profile file not found at path: $ProfilePath"
        }
    }

    $config.profiles[$ProfileName] = @{
        path = $ProfilePath
    }
    Save-Config $config
}

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
    $profileData = Get-Content $profilePath | ConvertFrom-Json

    if ($profileData.type -eq 'local') {
        $securePassword = Read-Host "Enter new certificate password" -AsSecureString
        Save-SecureInput -ProfileName $ProfileName -InputAlias "pwd" -SecureInput $securePassword
    }
    else {
        $secureSecret = Read-Host "Enter new client secret" -AsSecureString
        Save-SecureInput -ProfileName $ProfileName -InputAlias "kvs" -SecureInput $secureSecret
    }
}

function Remove-SignProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter()]
        [switch]$RemoveFile
    )

    $config = Get-Config
    if (-not $config.profiles.ContainsKey($ProfileName)) {
        throw "Profile '$ProfileName' not found"
    }

    $profilePath = $config.profiles[$ProfileName].path
    $config.profiles.Remove($ProfileName)
    Save-Config $config

    if ($RemoveFile -or ($profilePath.StartsWith($script:PROFILES_DIR) -and 
        (Read-Host "Do you want to delete the profile file? (Y/N)").ToUpper() -eq 'Y')) {
        if (Test-Path $profilePath) {
            Remove-Item $profilePath -Force
        }
        # Remove secure input files
        Get-ChildItem $script:PROFILES_DIR -Filter "$ProfileName-*" | Remove-Item -Force
    }
}

function Clear-SignProfiles {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$RemoveFiles
    )

    $config = Get-Config
    $config.profiles = @{}
    Save-Config $config

    if ($RemoveFiles -or (Read-Host "Do you want to delete all profile files? (Y/N)").ToUpper() -eq 'Y') {
        Get-ChildItem $script:PROFILES_DIR -File | Remove-Item -Force
    }
}

function Export-SignedExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Files
    )

    begin {
        $config = Get-Config
        if (-not $config.profiles.ContainsKey($ProfileName)) {
            throw "Profile '$ProfileName' not found"
        }

        $profilePath = $config.profiles[$ProfileName].path
        $signingProfile = Get-Content $profilePath | ConvertFrom-Json

        $scriptPath = Join-Path $PSScriptRoot $(if ($signingProfile.type -eq 'local') { 'local-sign.ps1' } else { 'azure-sign.ps1' })
        if (-not (Test-Path $scriptPath)) {
            throw "Signing script not found: $scriptPath"
        }
    }

    process {
        foreach ($file in $Files) {
            if (-not (Test-Path $file)) {
                Write-Error "File not found: $file"
                continue
            }
            if ([System.IO.Path]::GetExtension($file) -ne '.exe') {
                Write-Error "File is not an executable: $file"
                continue
            }
        }

        & $scriptPath -ProfilePath $profilePath -Files $Files
    }
}
