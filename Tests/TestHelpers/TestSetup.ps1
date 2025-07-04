# TestSetup.ps1
# Common test setup functions and variables for Pester tests

# Module path
$script:ModuleRoot = (Get-Item (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))).FullName
$script:ModuleName = "SignModule"
$script:ScriptsPath = Join-Path -Path $ModuleRoot -ChildPath "Scripts"
$script:ModulePath = Join-Path -Path $ModuleRoot -ChildPath "$ModuleName.psm1"
$script:TestsPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..")).Path
$script:TestDataPath = Join-Path -Path $TestsPath -ChildPath "TestData"
$script:TempPath = Join-Path -Path $TestDataPath -ChildPath "temp"  
$script:TestHelpersPath = Join-Path -Path $TestsPath -ChildPath "TestHelpers"

# Test profile paths
$script:TestConfigPath = Join-Path -Path $TestDataPath -ChildPath "config.json"
$script:TestProfilesDir = Join-Path -Path $TestDataPath -ChildPath "profiles"
$script:TestFilesDir = Join-Path -Path $TestDataPath -ChildPath "files"

# Function to set up the test environment
function Initialize-TestEnvironment {
    # Create test directories if they don't exist
    if (-not (Test-Path $script:TestDataPath)) {
        New-Item -Path $script:TestDataPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path $script:TempPath)) {
        New-Item -Path $script:TempPath -ItemType Directory -Force | Out-Null
    }   
    
    if (-not (Test-Path $script:TestProfilesDir)) {
        New-Item -Path $script:TestProfilesDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $script:TestFilesDir)) {
        New-Item -Path $script:TestFilesDir -ItemType Directory -Force | Out-Null
    }
    
    # Create an empty test config file
    @{ profiles = @{} } | ConvertTo-Json | Set-Content -Path $script:TestConfigPath
}

# Function to clean up the test environment
function Remove-TestEnvironment {
    if (Test-Path $script:TestDataPath) {
        Remove-Item -Path $script:TestDataPath -Recurse -Force
    }
}

# Function to create a test profile
function New-TestProfile {
    param (
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter(Mandatory)]
        [ValidateSet('local', 'azure')]
        [string]$ProfileType
    )
    
    $profilePath = Join-Path -Path $script:TestProfilesDir -ChildPath "$ProfileName.json"
    
    if ($ProfileType -eq 'local') {
        $profileData = @{
            type = 'local'
            signToolPath = 'C:\Test\SignTool.exe'
            certificatePath = 'C:\Test\Certificate.pfx'
            additionalParams = '/tr http://timestamp.test'
        }
    }
    else {
        $profileData = @{
            type = 'azure'
            signToolPath = 'C:\Test\AzureSignTool.exe'
            keyVaultUrl = 'https://testvault.vault.azure.net/'
            tenantId = '00000000-0000-0000-0000-000000000000'
            clientId = '11111111-1111-1111-1111-111111111111'
            certificateName = 'TestCert'
            additionalParams = '-tr http://timestamp.test'
        }
    }
    
    $profileData | ConvertTo-Json | Set-Content -Path $profilePath
    
    # Create mock secure inputs
    if ($ProfileType -eq 'local') {
        $secureFileName = "$ProfileName-pwd"
    }
    else {
        $secureFileName = "$ProfileName-kvs"
    }
    
    $secureFilePath = Join-Path -Path $script:TestProfilesDir -ChildPath $secureFileName
    "MockSecureContent" | Set-Content -Path $secureFilePath
    
    return $profilePath
}

# Mock functions to override specific behaviors
function Mock-SecureString {
    param(
        [string]$InputString = "MockPassword"
    )
    
    $secureString = ConvertTo-SecureString -String $InputString -AsPlainText -Force
    return $secureString
}

# Import module for testing - note this is a helper for when you need 
# to test the module directly rather than the individual functions
function Import-ModuleForTesting {
    # Save original values
    $originalConfigFile = $null
    $originalProfilesDir = $null
    
    # Load the module
    if (Get-Module -Name $script:ModuleName) {
        Remove-Module -Name $script:ModuleName -Force
    }
    
    # Import the module with a different scope
    Import-Module -Name $script:ModulePath -Force
    
    # Override script variables in the module
    $module = Get-Module -Name $script:ModuleName
    
    # Get the original values for later restoration
    $originalConfigFile = & $module { $script:CONFIG_FILE }
    $originalProfilesDir = & $module { $script:PROFILES_DIR }
    
    # Set the test paths
    & $module { 
        $script:CONFIG_FILE = $using:TestConfigPath
        $script:PROFILES_DIR = $using:TestProfilesDir
    }
    
    # Return original values for restoration
    return @{
        ConfigFile = $originalConfigFile
        ProfilesDir = $originalProfilesDir
    }
}

# Restore original module settings
function Restore-ModuleSettings {
    param (
        [hashtable]$OriginalSettings
    )
    
    $module = Get-Module -Name $script:ModuleName
    
    # Restore the original settings
    & $module { 
        $script:CONFIG_FILE = $using:OriginalSettings.ConfigFile
        $script:PROFILES_DIR = $using:OriginalSettings.ProfilesDir
    }
}
