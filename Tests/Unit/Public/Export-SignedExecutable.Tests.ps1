BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # Import required private functions
    . "$ModuleRoot\Private\ConfigFunctions.ps1"
    . "$ModuleRoot\Private\SecurityFunctions.ps1"
    
    # Import the function being tested
    . "$ModuleRoot\Public\Export-SignedExecutable.ps1"
    
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

Describe "Export-SignedExecutable" {
    BeforeEach {
        # Clean up before each test
        if (Test-Path $TestConfigPath) { Remove-Item -Path $TestConfigPath -Force }
        if (Test-Path $TestProfilesDir) { Remove-Item -Path $TestProfilesDir -Recurse -Force }
        
        # Initialize test environment
        Initialize-TestEnvironment
        
        # Create test profiles directory
        New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
        
        # Create test script directory
        $scriptsDir = Join-Path $ModuleRoot "Scripts"
        if (-not (Test-Path $scriptsDir)) {
            New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
        }
        
        # Create test files directory
        $testFilesDir = Join-Path $TestDataPath "files"
        New-Item -Path $testFilesDir -ItemType Directory -Force | Out-Null
        
        # Create a test .exe file
        $testExePath = Join-Path $testFilesDir "test.exe"
        "dummy content" | Set-Content -Path $testExePath
        
        # Create a test non-exe file
        $testTxtPath = Join-Path $testFilesDir "test.txt"
        "dummy content" | Set-Content -Path $testTxtPath
        
        # Create test profiles and add to config
        $config = @{ profiles = @{} }
        
        # Local profile
        $localProfilePath = Join-Path $TestProfilesDir "localProfile.json"
        @{ 
            type = "local"
            signToolPath = "C:\Test\SignTool.exe"
            certificatePath = "C:\Test\Certificate.pfx"
        } | ConvertTo-Json | Set-Content $localProfilePath
        "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "localProfile-pwd")
        $config.profiles["localProfile"] = @{ path = $localProfilePath }
        
        # Azure profile
        $azureProfilePath = Join-Path $TestProfilesDir "azureProfile.json"
        @{ 
            type = "azure"
            signToolPath = "C:\Test\AzureSignTool.exe"
            keyVaultUrl = "https://test.vault.azure.net/"
            tenantId = "00000000-0000-0000-0000-000000000000"
            clientId = "11111111-1111-1111-1111-111111111111"
            certificateName = "TestCert"
        } | ConvertTo-Json | Set-Content $azureProfilePath
        "MockSecureContent" | Set-Content (Join-Path $TestProfilesDir "azureProfile-kvs")
        $config.profiles["azureProfile"] = @{ path = $azureProfilePath }
        
        # Save config
        $config | ConvertTo-Json | Set-Content $TestConfigPath
        
        # Mock script file creation has been removed to prevent overwriting original scripts.
        # Script invocation will be mocked directly in relevant tests using Pester's Mock command.
        
        # Mock Write-Error to capture errors
        Mock Write-Error {}
    }
    
    Context "When profile doesn't exist" {
        It "Throws an error" {
            $testExePath = Join-Path $TestDataPath "files\test.exe"
            { Export-SignedExecutable -ProfileName "nonExistentProfile" -Files $testExePath } | Should -Throw
        }
    }
    
    Context "When file doesn't exist" {
        It "Writes an error and continues" {
            $nonExistentPath = Join-Path $TestDataPath "files\nonexistent.exe"
            
            Export-SignedExecutable -ProfileName "localProfile" -Files $nonExistentPath
            
            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*File not found*"
            }
        }
    }
    
    Context "When file is not an executable" {
        It "Writes an error and continues" {
            $testTxtPath = Join-Path $TestDataPath "files\test.txt"
            
            Export-SignedExecutable -ProfileName "localProfile" -Files $testTxtPath
            
            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*File is not an executable*"
            }
        }
    }
    
    Context "When using a local profile" {
        It "Calls the local signing script with correct parameters" {
            $testExePath = Join-Path $TestDataPath "files\test.exe"
            $localSignScriptPath = Join-Path $ModuleRoot "Scripts\local-sign.ps1"
            
            $script:calledScriptPathFromMock = $null
            $script:actualProfilePathFromMock = $null
            $script:actualFilesFromMock = $null
            
            Mock & {
                param($command) # First argument is the command
                $passedArgs = $args[1..($args.Length-1)]

                if ($command -eq $localSignScriptPath) {
                    $script:calledScriptPathFromMock = $command
                    $params = @{}
                    for ($i = 0; $i -lt $passedArgs.Length; $i += 2) {
                        $paramName = $passedArgs[$i].ToLower().TrimStart('-')
                        $params[$paramName] = $passedArgs[$i+1]
                    }
                    $script:actualProfilePathFromMock = $params['profilepath']
                    $script:actualFilesFromMock = $params['files']
                    Write-Output "Mocked local-sign.ps1 called for $($params['files'])"
                    $global:LASTEXITCODE = 0 
                } else {
                    Microsoft.PowerShell.Core\& $args
                }
            }
            
            Export-SignedExecutable -ProfileName "localProfile" -Files $testExePath
            
            $script:calledScriptPathFromMock | Should -Be $localSignScriptPath
            $script:actualProfilePathFromMock | Should -Be (Join-Path $TestProfilesDir "localProfile.json")
            $script:actualFilesFromMock | Should -BeExactly @($testExePath)
            Should -Not -Invoke Write-Error
        }
    }
    
    Context "When using an azure profile" {
        It "Calls the azure signing script with correct parameters" {
            $testExePath = Join-Path $TestDataPath "files\test.exe"
            $azureSignScriptPath = Join-Path $ModuleRoot "Scripts\azure-sign.ps1"

            $script:calledScriptPathFromMock = $null
            $script:actualProfilePathFromMock = $null
            $script:actualFilesFromMock = $null

            Mock & {
                param($command) # First argument is the command
                $passedArgs = $args[1..($args.Length-1)]

                if ($command -eq $azureSignScriptPath) {
                    $script:calledScriptPathFromMock = $command
                    $params = @{}
                    for ($i = 0; $i -lt $passedArgs.Length; $i += 2) {
                        $paramName = $passedArgs[$i].ToLower().TrimStart('-')
                        $params[$paramName] = $passedArgs[$i+1]
                    }
                    $script:actualProfilePathFromMock = $params['profilepath']
                    $script:actualFilesFromMock = $params['files']
                    Write-Output "Mocked azure-sign.ps1 called for $($params['files'])"
                    $global:LASTEXITCODE = 0 
                } else {
                    Microsoft.PowerShell.Core\& $args
                }
            }

            Export-SignedExecutable -ProfileName "azureProfile" -Files $testExePath

            $script:calledScriptPathFromMock | Should -Be $azureSignScriptPath
            $script:actualProfilePathFromMock | Should -Be (Join-Path $TestProfilesDir "azureProfile.json")
            $script:actualFilesFromMock | Should -BeExactly @($testExePath)
            Should -Not -Invoke Write-Error
        }
    }
}
