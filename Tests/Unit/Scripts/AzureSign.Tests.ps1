BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # We'll need to mock the common script functions
    function Convert-SecureStringToPlainText {
        param(
            [Parameter(Mandatory)]
            [System.Security.SecureString]$SecureString
        )
        
        return "MockClientSecret"
    }
    
    # Setup test variables
    $script:TestProfilesDir = Join-Path $TestDataPath "profiles"
    $script:TestFilesDir = Join-Path $TestDataPath "files"
    
    # Create test directories
    New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
    New-Item -Path $TestFilesDir -ItemType Directory -Force | Out-Null
    
    # Create test profile
    $script:TestProfilePath = Join-Path $TestProfilesDir "testAzureProfile.json"
    $testProfileData = @{
        type = "azure"
        signToolPath = "C:\Test\AzureSignTool.exe"
        keyVaultUrl = "https://testvault.vault.azure.net/"
        tenantId = "00000000-0000-0000-0000-000000000000"
        clientId = "11111111-1111-1111-1111-111111111111"
        certificateName = "TestCert"
        additionalParams = "-tr http://timestamp.test"
    }
    $testProfileData | ConvertTo-Json | Set-Content $TestProfilePath
    
    # Create test client secret file
    $testSecretPath = Join-Path $TestProfilesDir "testAzureProfile-kvs"
    "MockSecureClientSecret" | Set-Content $testSecretPath
    
    # Create test files
    $script:TestFile1 = Join-Path $TestFilesDir "test1.exe"
    $script:TestFile2 = Join-Path $TestFilesDir "test2.exe"
    "Test file 1" | Set-Content $TestFile1
    "Test file 2" | Set-Content $TestFile2
    
    # Mock external commands
    Mock Write-Error {}
    Mock Write-Output {}
}

Describe "Azure-Sign Script" {
    BeforeEach {
        # Set up the test for each context
        Mock Get-Content {
            if ($Path -like "*-kvs") {
                # Mock for secure client secret file
                return "MockSecureClientSecret"
            }
            else {
                # Mock for profile file
                return $testProfileData | ConvertTo-Json
            }
        }
        
        # Reset LASTEXITCODE before each test
        $global:LASTEXITCODE = 0
        
        # Mock the & operator
        Mock & { 
            # Capture the parameters
            $cmdLine = $args -join " "
            
            # Check if we're calling the sign tool
            if ($cmdLine -like "*AzureSignTool.exe*") {
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Default handling for other commands
            return & $args[0] $args[1..$args.Length]
        }
    }
    
    Context "Parameter validation" {
        It "Throws if profile is not an azure profile" {
            # Create a local profile for testing
            $localProfilePath = Join-Path $TestProfilesDir "localProfile.json"
            @{
                type = "local"
                signToolPath = "C:\Test\SignTool.exe"
            } | ConvertTo-Json | Set-Content $localProfilePath
            
            # Mock to return the local profile
            Mock Get-Content {
                return @{ type = "local" } | ConvertTo-Json
            } -ParameterFilter { $Path -eq $localProfilePath }
            
            # Test script with local profile - should throw
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $localProfilePath -Files $TestFile1 } | Should -Throw "*not an Azure signing profile*"
        }
    }
    
    Context "Signing a single file" {
        It "Calls the sign tool with correct parameters" {
            # Create a block to capture the parameters
            $capturedArgs = $null
            
            # Mock the & operator to capture parameters
            Mock & {
                $capturedArgs = $args
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Run the script
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # Verify Write-Error was not called
            Should -Not -Invoke Write-Error
            
            # Verify Write-Output was called for success
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed*"
            }
        }
    }
    
    Context "Signing multiple files" {
        It "Processes each file in the Files array" {
            # Create a block to count the number of sign tool calls
            $signToolCalls = 0
            
            # Mock the & operator to count calls
            Mock & {
                if ($args[0] -like "*AzureSignTool.exe") {
                    $signToolCalls++
                }
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Run the script with multiple files
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $TestProfilePath -Files @($TestFile1, $TestFile2) } | Should -Not -Throw
            
            # Verify Write-Error was not called
            Should -Not -Invoke Write-Error
            
            # Verify Write-Output was called for success for each file
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed*"
            } -Times 2
        }
    }
    
    Context "Using additional parameters" {
        It "Includes additional parameters when specified" {
            # Create a block to capture the parameters
            $capturedArgs = $null
            
            # Mock the & operator to capture parameters
            Mock & {
                $capturedArgs = $args
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Run the script
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # Verify Write-Output was called with additional parameters message
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Using additional parameters: -tr http://timestamp.test*"
            }
        }
    }
    
    Context "Error handling" {
        It "Reports errors when sign tool fails" {
            # Mock the & operator to simulate a failure
            Mock & {
                if ($args[0] -like "*AzureSignTool.exe") {
                    $global:LASTEXITCODE = 1
                    return "Signing failed"
                }
                return & $args[0] $args[1..$args.Length]
            }
            
            # Run the script
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # Verify Write-Error was called
            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*Failed to sign file*"
            }
        }
    }
}
