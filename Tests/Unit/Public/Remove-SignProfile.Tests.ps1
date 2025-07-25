BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    # Import required private functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"

    # Import the function being tested
    . "$ModuleRoot\Public\Remove-SignProfile.ps1"

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

Describe "Remove-SignProfile" {
    BeforeEach {
        # Clean up before each test
        if (Test-Path $TestConfigPath) { Remove-Item -Path $TestConfigPath -Force }
        if (Test-Path $TestProfilesDir) { Remove-Item -Path $TestProfilesDir -Recurse -Force }

        # Initialize test environment
        Initialize-TestEnvironment

        # Create test profiles directory
        New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null

        # Create a test external profiles directory
        $externalProfilesDir = Join-Path $TestDataPath "external"
        New-Item -Path $externalProfilesDir -ItemType Directory -Force | Out-Null

        # Create test profiles and add to config
        $config = @{ profiles = @{} }

        # Internal profile
        $internalProfilePath = Join-Path $TestProfilesDir "internalProfile.json"
        @{ type = "local" } | ConvertTo-Json | Set-Content $internalProfilePath
        "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "internalProfile-pwd")
        $config.profiles["internalProfile"] = @{ path = $internalProfilePath }

        # External profile
        $externalProfilePath = Join-Path $externalProfilesDir "externalProfile.json"
        @{ type = "local" } | ConvertTo-Json | Set-Content $externalProfilePath
        "MockSecureContent" | Set-Content (Join-Path $externalProfilesDir "externalProfile-pwd")
        $config.profiles["externalProfile"] = @{ path = $externalProfilePath }

        # Save config
        $config | ConvertTo-Json | Set-Content $TestConfigPath
    }

    Context "When profile doesn't exist" {
        It "Throws an error" {
            { Remove-SignProfile -ProfileName "nonExistentProfile" } | Should -Throw
        }
    }

    Context "When removing an internal profile" {
        It "Removes the profile from config and deletes the files" {
            # Verify files exist before removal
            Test-Path (Join-Path $TestProfilesDir "internalProfile.json") | Should -Be $true
            Test-Path (Join-Path $TestProfilesDir "internalProfile-pwd") | Should -Be $true

            # Call function
            Remove-SignProfile -ProfileName "internalProfile"

            # Verify profile was removed from config
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles.PSObject.Properties.Name -contains "internalProfile" | Should -Be $false

            # Verify files were deleted
            Test-Path (Join-Path $TestProfilesDir "internalProfile.json") | Should -Be $false
            Test-Path (Join-Path $TestProfilesDir "internalProfile-pwd") | Should -Be $false
        }
    }

    Context "When removing an external profile without RemoveFile switch" {
        It "Removes the profile from config but doesn't delete the files" {
            # Verify files exist before removal
            $externalProfilesDir = Join-Path $TestDataPath "external"
            Test-Path (Join-Path $externalProfilesDir "externalProfile.json") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile-pwd") | Should -Be $true

            # Call function
            Remove-SignProfile -ProfileName "externalProfile"

            # Verify profile was removed from config
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles.PSObject.Properties.Name -contains "externalProfile" | Should -Be $false

            # Verify files still exist
            Test-Path (Join-Path $externalProfilesDir "externalProfile.json") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile-pwd") | Should -Be $true
        }
    }

    Context "When removing an external profile with RemoveFile switch" {
        It "Removes the profile from config and deletes the files" {
            # Verify files exist before removal
            $externalProfilesDir = Join-Path $TestDataPath "external"
            Test-Path (Join-Path $externalProfilesDir "externalProfile.json") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile-pwd") | Should -Be $true

            # Call function
            Remove-SignProfile -ProfileName "externalProfile" -RemoveFile

            # Verify profile was removed from config
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles.PSObject.Properties.Name -contains "externalProfile" | Should -Be $false

            # Verify files were deleted
            Test-Path (Join-Path $externalProfilesDir "externalProfile.json") | Should -Be $false
            Test-Path (Join-Path $externalProfilesDir "externalProfile-pwd") | Should -Be $false
        }
    }
}
