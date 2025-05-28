BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # Import required private functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"
    
    # Import the function being tested
    . "$ModuleRoot\Public\Clear-SignProfiles.ps1"
    
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

Describe "Clear-SignProfiles" {
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
        
        # Internal profiles
        1..3 | ForEach-Object {
            $internalProfileName = "internalProfile$_"
            $internalProfilePath = Join-Path $TestProfilesDir "$internalProfileName.json"
            @{ type = "local" } | ConvertTo-Json | Set-Content $internalProfilePath
            "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "$internalProfileName-pwd")
            $config.profiles[$internalProfileName] = @{ path = $internalProfilePath }
        }
        
        # External profiles
        1..2 | ForEach-Object {
            $externalProfileName = "externalProfile$_"
            $externalProfilePath = Join-Path $externalProfilesDir "$externalProfileName.json"
            @{ type = "local" } | ConvertTo-Json | Set-Content $externalProfilePath
            "MockSecureContent" | Set-Content (Join-Path $externalProfilesDir "$externalProfileName-pwd")
            $config.profiles[$externalProfileName] = @{ path = $externalProfilePath }
        }
        
        # Save config
        $config | ConvertTo-Json | Set-Content $TestConfigPath
    }
    
    Context "When clearing without RemoveFile switch" {
        It "Removes all internal profiles but keeps external profiles in config" {
            # Verify initial state
            $initialConfig = Get-Content $TestConfigPath | ConvertFrom-Json
            $initialConfig.profiles.PSObject.Properties.Name.Count | Should -Be 5
            
            # Call function
            Clear-SignProfiles
            
            # Verify internal profiles were removed from the directory
            Get-ChildItem $TestProfilesDir -File | Should -BeNullOrEmpty
            
            # Verify external profiles still exist
            $externalProfilesDir = Join-Path $TestDataPath "external"
            Test-Path (Join-Path $externalProfilesDir "externalProfile1.json") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile1-pwd") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile2.json") | Should -Be $true
            Test-Path (Join-Path $externalProfilesDir "externalProfile2-pwd") | Should -Be $true
            
            # Verify config only contains external profiles
            $updatedConfig = Get-Content $TestConfigPath | ConvertFrom-Json
            $updatedConfig.profiles.PSObject.Properties.Name.Count | Should -Be 2
            $updatedConfig.profiles.PSObject.Properties.Name -contains "externalProfile1" | Should -Be $true
            $updatedConfig.profiles.PSObject.Properties.Name -contains "externalProfile2" | Should -Be $true
        }
    }
    
    Context "When clearing with RemoveFile switch" {
        It "Removes all profiles and files from both internal and external locations" {
            # Verify initial state
            $initialConfig = Get-Content $TestConfigPath | ConvertFrom-Json
            $initialConfig.profiles.PSObject.Properties.Name.Count | Should -Be 5
            
            # Call function
            Clear-SignProfiles -RemoveFile
            
            # Verify internal profiles were removed from the directory
            Get-ChildItem $TestProfilesDir -File | Should -BeNullOrEmpty
            
            # Verify external profiles were removed
            $externalProfilesDir = Join-Path $TestDataPath "external"
            Test-Path (Join-Path $externalProfilesDir "externalProfile1.json") | Should -Be $false
            Test-Path (Join-Path $externalProfilesDir "externalProfile1-pwd") | Should -Be $false
            Test-Path (Join-Path $externalProfilesDir "externalProfile2.json") | Should -Be $false
            Test-Path (Join-Path $externalProfilesDir "externalProfile2-pwd") | Should -Be $false
            
            # Verify config is empty
            $updatedConfig = Get-Content $TestConfigPath | ConvertFrom-Json
            $updatedConfig.profiles.PSObject.Properties.Name.Count | Should -Be 0
        }
    }
}
