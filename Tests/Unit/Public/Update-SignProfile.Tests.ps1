BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # Import required private functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"
    
    # Import the function being tested
    . "$ModuleRoot\Public\Update-SignProfile.ps1"
    
    # Set up the test environment
    Initialize-TestEnvironment
    
    # Override script variables for testing
    $script:CONFIG_FILE = $TestConfigPath
    $script:PROFILES_DIR = $TestProfilesDir
}

AfterAll {
    # Clean up
    Remove-TestEnvironment
}

Describe "Update-SignProfile" {
    BeforeEach {
        # Clean up before each test
        if (Test-Path $TestConfigPath) { Remove-Item -Path $TestConfigPath -Force }
        if (Test-Path $TestProfilesDir) { Remove-Item -Path $TestProfilesDir -Recurse -Force }
        
        # Initialize test environment
        Initialize-TestEnvironment
        
        # Create a test profile
        $profileName = "testProfile"
        $profilePath = Join-Path $TestProfilesDir "$profileName.json"
        
        # Create a local profile
        $localProfileData = @{
            type = "local"
            signToolPath = "C:\Test\SignTool.exe"
            certificatePath = "C:\Test\Certificate.pfx"
            additionalParams = "/tr http://timestamp.test"
        }
        
        # Create an azure profile
        $azureProfileData = @{
            type = "azure"
            signToolPath = "C:\Test\AzureSignTool.exe"
            keyVaultUrl = "https://testvault.vault.azure.net/"
            tenantId = "00000000-0000-0000-0000-000000000000"
            clientId = "11111111-1111-1111-1111-111111111111"
            certificateName = "TestCert"
            additionalParams = "-tr http://timestamp.test"
        }
        
        # Create the profiles directory
        New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
        
        # Add profiles to config
        $config = @{ profiles = @{} }
        $config.profiles["localProfile"] = @{ path = (Join-Path $TestProfilesDir "localProfile.json") }
        $config.profiles["azureProfile"] = @{ path = (Join-Path $TestProfilesDir "azureProfile.json") }
        $config | ConvertTo-Json | Set-Content $TestConfigPath
        
        # Create profile files
        $localProfileData | ConvertTo-Json | Set-Content (Join-Path $TestProfilesDir "localProfile.json")
        $azureProfileData | ConvertTo-Json | Set-Content (Join-Path $TestProfilesDir "azureProfile.json")
        
        # Create secure input files
        "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "localProfile-pwd")
        "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "azureProfile-kvs")
        
        # Mock Write-Host to avoid output in tests
        Mock Write-Host {}
    }
    
    Context "When profile doesn't exist" {
        It "Throws an error" {
            { Update-SignProfile -ProfileName "nonExistentProfile" } | Should -Throw
        }
    }
    
    Context "When updating a local profile" {
        BeforeEach {
            # Mock Read-Host to return known values
            Mock Read-Host {
                param($Prompt)
                switch -Regex ($Prompt) {
                    "Update certificate password" { return "y" }
                    "Update additional parameters" { return "y" }
                    "Enter new additional parameters" { return "/tr http://new.timestamp.test" }
                }
            }
            
            # Mock SecureString input
            Mock Read-Host {
                param($Prompt)
                if ($Prompt -match "password") {
                    return (ConvertTo-SecureString "NewPassword" -AsPlainText -Force)
                }
            } -ParameterFilter { $AsSecureString }
        }
        
        It "Updates the password and additional parameters" {
            # Call function
            Update-SignProfile -ProfileName "localProfile"
            
            # Verify profile was updated
            $profilePath = Join-Path $TestProfilesDir "localProfile.json"
            $profile = Get-Content $profilePath | ConvertFrom-Json
            $profile.additionalParams | Should -Be "/tr http://new.timestamp.test"
            
            # Verify secure input file was updated
            $secureInputPath = Join-Path $TestProfilesDir "localProfile-pwd"
            Test-Path $secureInputPath | Should -Be $true
            # We can't verify the content directly since it's encrypted
        }
    }
    
    Context "When updating an azure profile" {
        BeforeEach {
            # Mock Read-Host to return known values
            Mock Read-Host {
                param($Prompt)
                switch -Regex ($Prompt) {
                    "Update client secret" { return "y" }
                    "Update additional parameters" { return "y" }
                    "Enter new additional parameters" { return "-tr http://new.timestamp.test" }
                }
            }
            
            # Mock SecureString input
            Mock Read-Host {
                param($Prompt)
                if ($Prompt -match "client secret") {
                    return (ConvertTo-SecureString "NewSecret" -AsPlainText -Force)
                }
            } -ParameterFilter { $AsSecureString }
        }
        
        It "Updates the client secret and additional parameters" {
            # Call function
            Update-SignProfile -ProfileName "azureProfile"
            
            # Verify profile was updated
            $profilePath = Join-Path $TestProfilesDir "azureProfile.json"
            $profile = Get-Content $profilePath | ConvertFrom-Json
            $profile.additionalParams | Should -Be "-tr http://new.timestamp.test"
            
            # Verify secure input file was updated
            $secureInputPath = Join-Path $TestProfilesDir "azureProfile-kvs"
            Test-Path $secureInputPath | Should -Be $true
            # We can't verify the content directly since it's encrypted
        }
    }
    
    Context "When choosing not to update anything" {
        BeforeEach {
            # Mock Read-Host to return known values
            Mock Read-Host {
                param($Prompt)
                switch -Regex ($Prompt) {
                    "Update (certificate password|client secret)" { return "n" }
                    "Update additional parameters" { return "n" }
                }
            }
        }
        
        It "Makes no changes to the profile" {
            # Get original profile
            $profilePath = Join-Path $TestProfilesDir "localProfile.json"
            $originalProfile = Get-Content $profilePath | ConvertFrom-Json -AsHashtable
            $originalSecureInputContent = Get-Content (Join-Path $TestProfilesDir "localProfile-pwd")
            
            # Call function
            Update-SignProfile -ProfileName "localProfile"
            
            # Verify profile was not changed
            $updatedProfile = Get-Content $profilePath | ConvertFrom-Json -AsHashtable
            $updatedSecureInputContent = Get-Content (Join-Path $TestProfilesDir "localProfile-pwd")
            
            $updatedProfile.additionalParams | Should -Be $originalProfile.additionalParams
            $updatedSecureInputContent | Should -Be $originalSecureInputContent
        }
    }
}
