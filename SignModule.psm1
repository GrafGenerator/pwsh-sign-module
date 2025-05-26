using namespace System.Security
using namespace System.IO

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

function Test-ProfileName {
    param([string]$ProfileName)
    if ($ProfileName -notmatch '^[a-zA-Z0-9_\-]+$') {
        throw "Profile name '$ProfileName' is invalid. Must contain only alphabetic, numeric, underscore and hyphen characters"
    }
}

function Save-SecureInput {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [Parameter(Mandatory)]
        [string]$InputAlias,

        [Parameter(Mandatory)]
        [SecureString]$SecureInput
    )
    Test-ProfileName -ProfileName $ProfileName

    $profileFolderPath = [FileInfo]::new($ProfilePath).Directory.FullName;
    $secretFileName = "$ProfileName-$InputAlias";
    $secretFilePath = Join-Path $profileFolderPath $secretFileName;

    $SecureInput | ConvertFrom-SecureString | Set-Content $secretFilePath
}

function Get-SecureInput {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter(Mandatory)]
        [string]$ProfilePath,
    
        [Parameter(Mandatory)]
        [string]$InputAlias
    )
    Test-ProfileName -ProfileName $ProfileName

    $profileFolderPath = [FileInfo]::new($ProfilePath).Directory.FullName;
    $secretFileName = "$ProfileName-$InputAlias";
    $secretFilePath = Join-Path $profileFolderPath $secretFileName;

    if (Test-Path $secretFilePath) {
        Get-Content $secretFilePath | ConvertTo-SecureString
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
        }
        else {
            $profileData.signToolPath = Read-Host "Enter path to azure sign tool installation"
            $profileData.keyVaultUrl = Read-Host "Enter key vault URL"
            $profileData.tenantId = Read-Host "Enter tenant ID"
            $profileData.clientId = Read-Host "Enter client ID"
            $profileData.certificateName = Read-Host "Enter certificate name"

            $secureSecret = Read-Host "Enter client secret" -AsSecureString
            Save-SecureInput -ProfileName $ProfileName -ProfilePath $targetProfilePath -InputAlias "kvs" -SecureInput $secureSecret
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
        Save-SecureInput -ProfileName $ProfileName -ProfilePath $profilePath -InputAlias "pwd" -SecureInput $securePassword
    }
    else {
        $secureSecret = Read-Host "Enter new client secret" -AsSecureString
        Save-SecureInput -ProfileName $ProfileName -ProfilePath $profilePath -InputAlias "kvs" -SecureInput $secureSecret
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
