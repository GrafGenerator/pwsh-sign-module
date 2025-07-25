[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function')]
param()

BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    . $script:ScriptsPath\common.ps1

    Initialize-TestEnvironment

    # Create test profile
    $script:TestProfilePath = Join-Path $script:TestProfilesDir "testLocalProfile.json"

    $script:testPassword = "MockSecurePassword"

    # Create test password file
    $script:testPasswordPath = Join-Path $script:TestProfilesDir "testLocalProfile-pwd"
    $script:testPassword | Set-Content $script:testPasswordPath

    $script:testPasswordSecureString = ConvertTo-SecureString -String $testPassword -AsPlainText -Force

    # Test file names
    $script:TestFile1 = Join-Path $script:TestFilesDir "test1.exe"
    $script:TestFile2 = Join-Path $script:TestFilesDir "test2.exe"

    # Mock external commands
    Mock Write-Error {}
    Mock Write-Output {}
}

AfterAll {
    Remove-TestEnvironment
}

Describe "Local-Sign Script" {
    BeforeEach {
        $testSession = New-Object TestSessionHelper -ArgumentList $script:TempPath, "testLocalProfile-signResult-"

        $additionalParam1 = "/tr"
        $additionalParam2 = "http://timestamp.test"

        # Create test profile
        $testProfileData = @{
            type = "local"
            signToolPath = $script:TestSignToolPath
            certificatePath = "C:\Test\Certificate.pfx"
            additionalParams = "$additionalParam1 $additionalParam2 --testOutFile $($testSession.FilePath)"
        }
        $testProfileData | ConvertTo-Json | Set-Content $script:TestProfilePath

        # Set up the test for each context
        Mock Convert-SecureStringToPlainText {
            return $script:testPassword
        }

        Mock ConvertTo-SecureString {
            return $script:testPasswordSecureString
        }
    }

    AfterEach {
        Remove-Item $testSession.FilePath -ErrorAction SilentlyContinue
    }

    Context "Parameter validation" {
        It "Throws if profile is not a local profile" {
            # Create an azure profile for testing
            $azureProfilePath = Join-Path $script:TestProfilesDir "azureProfile.json"
            @{
                type = "azure"
                signToolPath = "C:\Test\AzureSignTool.exe"
            } | ConvertTo-Json | Set-Content $azureProfilePath

            # Test script with azure profile - should throw
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $azureProfilePath -Files $script:TestFile1 } | Should -Throw "*not a local signing profile*"
        }
    }

    Context "Signing a single file" {
        It "Calls the sign tool with correct parameters" {
            # Run the script
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw

            $capturedSignToolArgs = $testSession.GetCapturedLines()

            $capturedCommand = $capturedSignToolArgs[0]

            # Verify SignTool.exe was called
            $capturedCommand | Should -Be $testProfileData.signToolPath

            # Verify arguments passed to SignTool.exe
            $capturedSignToolArgs | Should -Contain "sign"
            $capturedSignToolArgs | Should -Contain "/f"
            $capturedSignToolArgs | Should -Contain $testProfileData.certificatePath
            $capturedSignToolArgs | Should -Contain "/p"
            $capturedSignToolArgs | Should -Contain $script:testPassword
            $capturedSignToolArgs | Should -Contain $additionalParam1
            $capturedSignToolArgs | Should -Contain $additionalParam2
            $capturedSignToolArgs | Should -Contain $script:TestFile1

            Should -Not -Invoke Write-Error
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed files: $script:TestFile1*"
            }
        }
    }

    Context "Signing multiple files" {
        It "Processes each file in the Files array" {
            # Run the script with multiple files
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $script:TestProfilePath -Files @($script:TestFile1, $script:TestFile2) } | Should -Not -Throw

            $capturedSignToolArgs = $testSession.GetCapturedLines()

            $capturedSignToolArgs | Should -Contain $script:TestFile1
            $capturedSignToolArgs | Should -Contain $script:TestFile2

            Should -Not -Invoke Write-Error
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed files*"
            }
        }
    }

    Context "Using additional parameters" {
        It "Includes additional parameters when specified" {
            # Run the script
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw

            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Using additional parameters: $additionalParam1 $additionalParam2*"
            }
        }
    }

    Context "Error handling" {
        It "Reports errors when sign tool fails" {
            # Create test profile
            $testProfileData.additionalParams += " --exitCode 123"
            $testProfileData | ConvertTo-Json | Set-Content $script:TestProfilePath

            # Run the script
            { . "$ModuleRoot\Scripts\local-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw

            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*Failed to sign files*"
            }
        }
    }
}