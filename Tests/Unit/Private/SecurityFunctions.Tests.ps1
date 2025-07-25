[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function')]
param()

BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    # Import required functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"

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

Describe "SecurityFunctions" {
    Context "Save-SecureInput" {
        BeforeEach {
            $testProfileName = "testProfile"
            $testProfilePath = Join-Path $TestProfilesDir "$testProfileName.json"

            # Create test profile directory and file
            if (-not (Test-Path $TestProfilesDir)) {
                New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
            }

            @{ type = "local" } | ConvertTo-Json | Set-Content -Path $testProfilePath

            # Create a test secure string
            $script:testSecureString = ConvertTo-SecureString "TestPassword" -AsPlainText -Force
        }

        AfterEach {
            # Clean up test files
            if (Test-Path $TestProfilesDir) {
                Remove-Item -Path $TestProfilesDir -Recurse -Force
            }
        }

        It "Saves secure input to a file" {
            $testAlias = "pwd"

            # Call function
            Save-SecureInput -ProfileName "testProfile" -ProfilePath $testProfilePath -InputAlias $testAlias -SecureInput $script:testSecureString

            # Verify file was created
            $secureFilePath = Join-Path $TestProfilesDir "testProfile-pwd"
            Test-Path $secureFilePath | Should -Be $true

            # Content should exist (we can't verify exact content since it's encrypted)
            $content = Get-Content $secureFilePath
            $content | Should -Not -BeNullOrEmpty
        }

        It "Throws exception for invalid profile name" {
            # This should throw an exception
            {
                Save-SecureInput -ProfileName "invalid name" -ProfilePath $testProfilePath -InputAlias "pwd" -SecureInput $script:testSecureString
            } | Should -Throw
        }
    }

    Context "Get-SecureInput" {
        BeforeEach {
            $testProfileName = "testProfile"
            $testProfilePath = Join-Path $TestProfilesDir "$testProfileName.json"
            $testAlias = "pwd"
            $testSecureFilePath = Join-Path $TestProfilesDir "$testProfileName-$testAlias"

            # Create test profile directory and file
            if (-not (Test-Path $TestProfilesDir)) {
                New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
            }

            @{ type = "local" } | ConvertTo-Json | Set-Content -Path $testProfilePath

            # Create a test secure string and save it
            $script:testSecureString = ConvertTo-SecureString "TestPassword" -AsPlainText -Force
            $script:testSecureString | ConvertFrom-SecureString | Set-Content $testSecureFilePath
        }

        AfterEach {
            # Clean up test files
            if (Test-Path $TestProfilesDir) {
                Remove-Item -Path $TestProfilesDir -Recurse -Force
            }
        }

        It "Returns secure string when secure input file exists" {
            # Call function
            $result = Get-SecureInput -ProfileName "testProfile" -ProfilePath $testProfilePath -InputAlias "pwd"

            # Verify result is a secure string
            $result | Should -BeOfType [System.Security.SecureString]
        }

        It "Returns null when secure input file doesn't exist" {
            # Remove the secure input file
            Remove-Item -Path $testSecureFilePath -Force

            # Call function
            $result = Get-SecureInput -ProfileName "testProfile" -ProfilePath $testProfilePath -InputAlias "pwd"

            # Verify result is null
            $result | Should -BeNullOrEmpty
        }

        It "Throws exception for invalid profile name" {
            # This should throw an exception
            {
                Get-SecureInput -ProfileName "invalid name" -ProfilePath $testProfilePath -InputAlias "pwd"
            } | Should -Throw
        }
    }
}
