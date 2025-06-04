BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
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
        Mock Convert-SecureStringToPlainText {
            param(
                [System.Security.SecureString]$SecureString
            )
            return "MockPassword"
        }

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
            $script:capturedCommand = $null
            $script:capturedSignToolArgs = $null
            
            Mock & {
                param($command) # First argument is the command
                $passedArgs = $args[1..($args.Length-1)]

                if ($command -eq $testProfileData.signToolPath) {
                    $script:capturedCommand = $command
                    $script:capturedSignToolArgs = $passedArgs
                    $global:LASTEXITCODE = 0
                    return "Successfully signed"
                } elseif ($command -like "*.ps1") { # Allow .ps1 scripts (like common.ps1) to be dot-sourced
                    Microsoft.PowerShell.Core\& $args
                }
                # Other commands can be handled or ignored as needed for the test context
            }
            
            # Run the script
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $TestProfilePath -Files $TestFile1 } | Should -Not -Throw
            
            # Verify SignTool.exe was called
            $script:capturedCommand | Should -Be $testProfileData.signToolPath

            # Verify arguments passed to SignTool.exe
            # Expected: sign /f C:\Test\Certificate.pfx /p MockPassword /tr http://timestamp.test C:\projects\grafg\powershell\pwsh-sign-module\Tests\TestData\files\test1.exe
            $script:capturedSignToolArgs | Should -Contain "sign"
            $script:capturedSignToolArgs | Should -Contain "/f"
            $script:capturedSignToolArgs | Should -Contain $testProfileData.certificatePath
            $script:capturedSignToolArgs | Should -Contain "/p"
            $script:capturedSignToolArgs | Should -Contain "MockPassword" # From the mocked Convert-SecureStringToPlainText
            $script:capturedSignToolArgs | Should -Contain ($testProfileData.additionalParams -split ' ')[0] # First part of additional params
            $script:capturedSignToolArgs | Should -Contain ($testProfileData.additionalParams -split ' ')[1] # Second part of additional params
            $script:capturedSignToolArgs | Should -Contain $TestFile1
            
            Should -Not -Invoke Write-Error
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed file: $TestFile1*"
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
