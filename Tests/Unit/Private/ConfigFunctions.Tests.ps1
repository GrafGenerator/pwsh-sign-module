BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    # Import the private functions directly
    . "$ModuleRoot\Private\ConfigFunctions.ps1"

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

Describe "ConfigFunctions" {
    Context "Initialize-ModuleConfig" {
        BeforeEach {
            # Remove test files before each test to ensure clean state
            if (Test-Path $TestConfigPath) { Remove-Item -Path $TestConfigPath -Force }
            if (Test-Path $TestProfilesDir) { Remove-Item -Path $TestProfilesDir -Recurse -Force }
        }

        It "Creates config file if it doesn't exist" {
            # Verify config file doesn't exist
            Test-Path $TestConfigPath | Should -Be $false

            # Call function
            Initialize-ModuleConfig

            # Verify config file was created with correct content
            Test-Path $TestConfigPath | Should -Be $true
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles | Should -BeOfType [PSCustomObject]
        }

        It "Creates profiles directory if it doesn't exist" {
            # Verify profiles directory doesn't exist
            Test-Path $TestProfilesDir | Should -Be $false

            # Call function
            Initialize-ModuleConfig

            # Verify profiles directory was created
            Test-Path $TestProfilesDir | Should -Be $true
        }
    }

    Context "Get-Config" {
        BeforeEach {
            # Set up a known config file
            @{ profiles = @{ test = @{ path = "test.json" } } } | ConvertTo-Json | Set-Content -Path $TestConfigPath
        }

        It "Returns config as hashtable when config file exists" {
            $config = Get-Config
            $config | Should -BeOfType [System.Collections.Hashtable]
            $config.profiles.test.path | Should -Be "test.json"
        }

        It "Returns empty config when config file doesn't exist" {
            # Remove config file
            Remove-Item -Path $TestConfigPath -Force

            $config = Get-Config
            $config | Should -BeOfType [System.Collections.Hashtable]
            $config.profiles | Should -BeOfType [System.Collections.Hashtable]
            $config.profiles.Count | Should -Be 0
        }
    }

    Context "Save-Config" {
        It "Saves config to file" {
            $testConfig = @{ profiles = @{ newTest = @{ path = "newTest.json" } } }

            Save-Config -Config $testConfig

            # Verify file contents
            $savedConfig = Get-Content $TestConfigPath | ConvertFrom-Json
            $savedConfig.profiles.newTest.path | Should -Be "newTest.json"
        }
    }

    Context "Test-ProfileName" {
        It "Accepts valid profile names" {
            # These should not throw exceptions
            { Test-ProfileName -ProfileName "validName" } | Should -Not -Throw
            { Test-ProfileName -ProfileName "valid_name" } | Should -Not -Throw
            { Test-ProfileName -ProfileName "valid-name" } | Should -Not -Throw
            { Test-ProfileName -ProfileName "valid123" } | Should -Not -Throw
        }

        It "Throws exception for invalid profile names" {
            # These should throw exceptions
            { Test-ProfileName -ProfileName "invalid name" } | Should -Throw
            { Test-ProfileName -ProfileName "invalid*name" } | Should -Throw
            { Test-ProfileName -ProfileName "invalid/name" } | Should -Throw
            { Test-ProfileName -ProfileName "invalid\name" } | Should -Throw
            { Test-ProfileName -ProfileName "invalid.name" } | Should -Throw
        }
    }
}
