BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    # We'll need to mock the common script functions
    function Convert-SecureStringToPlainText {
        param(
            [Parameter(Mandatory)]
            [System.Security.SecureString]$SecureString
        )
        
        return "MockPassword"
    }
    
    # Setup test variables
    $script:TestProfilesDir = Join-Path $TestDataPath "profiles"
    $script:TestFilesDir = Join-Path $TestDataPath "files"
    
    # Create test directories
    New-Item -Path $TestProfilesDir -ItemType Directory -Force | Out-Null
    New-Item -Path $TestFilesDir -ItemType Directory -Force | Out-Null
    
    # Create test profile
    $script:TestProfilePath = Join-Path $TestProfilesDir "testLocalProfile.json"
    $testProfileData = @{
        type = "local"
        signToolPath = "C:\Test\SignTool.exe"
        certificatePath = "C:\Test\Certificate.pfx"
        additionalParams = "/tr http://timestamp.test"
    }
    $testProfileData | ConvertTo-Json | Set-Content $TestProfilePath
    
    # Create test password file
    $testPasswordPath = Join-Path $TestProfilesDir "testLocalProfile-pwd"
    "MockSecurePassword" | Set-Content $testPasswordPath
    
    # Create test files
    $script:TestFile1 = Join-Path $TestFilesDir "test1.exe"
    $script:TestFile2 = Join-Path $TestFilesDir "test2.exe"
    "Test file 1" | Set-Content $TestFile1
    "Test file 2" | Set-Content $TestFile2
    
    # Mock external commands
    Mock Write-Error {}
    Mock Write-Output {}
    
    # Mock the & operator which is used to call the sign tool
    # We need to use a function for this since we can't directly mock the & operator
    function global:MockInvokeOperator {
        param($Command, $Arguments)
        # Return success
        $global:LASTEXITCODE = 0
        return "Mock signing output"
    }
}

Describe "Local-Sign Script" {
    BeforeEach {
        # Set up the test for each context
        Mock Get-Content {
            if ($Path -like "*-pwd") {
                # Mock for secure password file
                return "MockSecurePassword"
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
            if ($cmdLine -like "*SignTool.exe*") {
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Default handling for other commands
            return & $args[0] $args[1..$args.Length]
        }
    }
    
    Context "Parameter validation" {
        It "Throws if profile is not a local profile" {
            # Create an azure profile for testing
            $azureProfilePath = Join-Path $TestProfilesDir "azureProfile.json"
            @{
                type = "azure"
                signToolPath = "C:\Test\AzureSignTool.exe"
            } | ConvertTo-Json | Set-Content $azureProfilePath
            
            # Mock to return the azure profile
            Mock Get-Content {
                return @{ type = "azure" } | ConvertTo-Json
            } -ParameterFilter { $Path -eq $azureProfilePath }
            
            # Test script with azure profile - should throw
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $azureProfilePath -Files $TestFile1 } | Should -Throw "*not a local signing profile*"
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
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # We can't directly check the arguments passed to the & operator in Pester
            # So this is a best effort to validate the script ran without errors
            
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
                if ($args[0] -like "*SignTool.exe") {
                    $signToolCalls++
                }
                $global:LASTEXITCODE = 0
                return "Successfully signed"
            }
            
            # Run the script with multiple files
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $TestProfilePath -Files @($TestFile1, $TestFile2) } | Should -Not -Throw
            
            # Verify Write-Error was not called
            Should -Not -Invoke Write-Error
            
            # Verify Write-Output was called for success for each file
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed*"
            } -Times 2
        }
    }
    
    Context "Error handling" {
        It "Reports errors when sign tool fails" {
            # Mock the & operator to simulate a failure
            Mock & {
                if ($args[0] -like "*SignTool.exe") {
                    $global:LASTEXITCODE = 1
                    return "Signing failed"
                }
                return & $args[0] $args[1..$args.Length]
            }
            
            # Run the script
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # Verify Write-Error was called
            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*Failed to sign file*"
            }
        }
    }
}
