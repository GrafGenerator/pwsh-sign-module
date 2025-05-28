BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # Import required private functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"
    
    # Import the function being tested
    . "$ModuleRoot\Public\Add-SignProfile.ps1"
    
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

Describe "Add-SignProfile" {
    BeforeEach {
        # Clean up before each test
        if (Test-Path $TestConfigPath) { Remove-Item -Path $TestConfigPath -Force }
        if (Test-Path $TestProfilesDir) { Remove-Item -Path $TestProfilesDir -Recurse -Force }
        
        # Initialize test environment
        Initialize-TestEnvironment
    }
    
    Context "When adding a new profile with provided profile path" {
        BeforeEach {
            # Create a test profile file
            $testProfileDir = Join-Path $TestDataPath "external"
            New-Item -Path $testProfileDir -ItemType Directory -Force | Out-Null
            $testProfilePath = Join-Path $testProfileDir "external-profile.json"
            @{ type = "local"; signToolPath = "C:\Test\SignTool.exe" } | ConvertTo-Json | Set-Content -Path $testProfilePath
        }
        
        It "Adds the profile to the configuration" {
            # Call function
            Add-SignProfile -ProfileName "externalProfile" -ProfilePath $testProfilePath
            
            # Verify config
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles.externalProfile.path | Should -Be $testProfilePath
        }
        
        It "Throws when profile name already exists" {
            # Add profile first
            Add-SignProfile -ProfileName "externalProfile" -ProfilePath $testProfilePath
            
            # Try to add again with same name
            { Add-SignProfile -ProfileName "externalProfile" -ProfilePath $testProfilePath } | Should -Throw
        }
        
        It "Throws when profile file doesn't exist" {
            $nonExistentPath = Join-Path $testProfileDir "non-existent.json"
            { Add-SignProfile -ProfileName "nonExistent" -ProfilePath $nonExistentPath } | Should -Throw
        }
    }
    
    Context "When adding a new profile with interactive input" {
        BeforeEach {
            # Mock Read-Host to return known values
            Mock Read-Host {
                param($Prompt)
                switch -Regex ($Prompt) {
                    "profile type" { return "local" }
                    "sign tool" { return "C:\Test\SignTool.exe" }
                    "certificate" { return "C:\Test\Certificate.pfx" }
                    "additional parameters" { return "/tr http://timestamp.test" }
                }
            }
            
            # Mock SecureString input
            Mock Read-Host {
                param($Prompt)
                if ($Prompt -match "password") {
                    return (ConvertTo-SecureString "TestPassword" -AsPlainText -Force)
                }
            } -ParameterFilter { $AsSecureString }
        }
        
        It "Creates a new profile file and adds it to configuration" {
            # Call function without providing ProfilePath (interactive mode)
            Add-SignProfile -ProfileName "newProfile"
            
            # Verify profile file was created
            $profilePath = Join-Path $TestProfilesDir "newProfile.json"
            Test-Path $profilePath | Should -Be $true
            
            # Verify config
            $config = Get-Content $TestConfigPath | ConvertFrom-Json
            $config.profiles.newProfile.path | Should -Be $profilePath
            
            # Verify profile contents
            $profile = Get-Content $profilePath | ConvertFrom-Json
            $profile.type | Should -Be "local"
            $profile.signToolPath | Should -Be "C:\Test\SignTool.exe"
            $profile.certificatePath | Should -Be "C:\Test\Certificate.pfx"
            $profile.additionalParams | Should -Be "/tr http://timestamp.test"
            
            # Verify secure input file was created
            $secureInputPath = Join-Path $TestProfilesDir "newProfile-pwd"
            Test-Path $secureInputPath | Should -Be $true
        }
    }
}
