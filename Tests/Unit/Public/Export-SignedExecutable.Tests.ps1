BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    . $script:ScriptsPath\common.ps1

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

    # Mock Write-Error to capture errors
    Mock Write-Error {}
    Mock Write-Warning {}
}

AfterAll {
    Remove-TestEnvironment
}

Describe "Export-SignedExecutable" {
    BeforeEach {
        $testSession = New-Object TestSessionHelper -ArgumentList $script:TempPath, "testExport-signResult-"

        # Create a test .exe file
        $testExePath = Join-Path $testFilesDir "test.exe"
        "dummy content" | Set-Content -Path $testExePath

        # Create a test non-exe file
        $testTxtPath = Join-Path $testFilesDir "test.txt"
        "dummy content" | Set-Content -Path $testTxtPath

        $testSecureContent = "MockSecureContent"
        $testSecureContentSecureString = ConvertTo-SecureString -String $testSecureContent -AsPlainText -Force

        # Create test profiles and add to config
        $config = @{ profiles = @{} }

        # Local profile
        $testLocalProfile = @{ 
            type = "local"
            signToolPath = $script:TestSignToolPath
            certificatePath = "C:\Test\Certificate.pfx"
            additionalParams = "--testOutFile $($testSession.FilePath)"
        }
        $localProfilePath = Join-Path $TestProfilesDir "localProfile.json"
        $testLocalProfile | ConvertTo-Json | Set-Content $localProfilePath

        $testSecureContent | Set-Content (Join-Path $TestProfilesDir "localProfile-pwd")
        $config.profiles["localProfile"] = @{ path = $localProfilePath }

        # Azure profile
        $testAzureProfile = @{ 
            type = "azure"
            signToolPath = $script:TestSignToolPath
            keyVaultUrl = "https://test.vault.azure.net/"
            tenantId = "00000000-0000-0000-0000-000000000000"
            clientId = "11111111-1111-1111-1111-111111111111"
            certificateName = "TestCert"
            additionalParams = "--testOutFile $($testSession.FilePath)"
        }
        $azureProfilePath = Join-Path $TestProfilesDir "azureProfile.json"
        $testAzureProfile | ConvertTo-Json | Set-Content $azureProfilePath

        $testSecureContent | Set-Content (Join-Path $TestProfilesDir "azureProfile-kvs")
        $config.profiles["azureProfile"] = @{ path = $azureProfilePath }

        # Save config
        $config | ConvertTo-Json | Set-Content $TestConfigPath

        # Set up the test for each context
        Mock Convert-SecureStringToPlainText {
            param(
                [System.Security.SecureString]$SecureString
            )
            return $testSecureContent
        }

        Mock ConvertTo-SecureString {
            return $testSecureContentSecureString
        }
    }

    AfterEach {
        Remove-Item $testSession.FilePath -ErrorAction SilentlyContinue
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

            Should -Invoke Write-Warning -ParameterFilter {
                $Message -like "*File not found*"
            }
        }
    }

    Context "When file is not an executable" {
        It "Writes an error and continues" {
            $testTxtPath = Join-Path $TestDataPath "files\test.txt"

            Export-SignedExecutable -ProfileName "localProfile" -Files $testTxtPath

            Should -Invoke Write-Warning -ParameterFilter {
                $Message -like "*File is not an executable*"
            }
        }
    }

    Context "When using a local profile" {
        It "Calls the local signing script with correct parameters" {
            $testFilePath = "files\test.exe"
            $testPathCmdlet = Get-Command Test-Path -CommandType Cmdlet
            Mock Test-Path {
                param(
                    [string[]]$Path
                )

                if ($Path -contains $testFilePath) {
                    return $true
                }

                return & $testPathCmdlet -Path $Path
            }

            Export-SignedExecutable -ProfileName "localProfile" -Files $testFilePath

            $capturedSignToolArgs = $testSession.GetCapturedLines()
            $capturedCommand = $capturedSignToolArgs[0]

            $capturedCommand | Should -Be $testLocalProfile.signToolPath
            $capturedSignToolArgs | Should -Contain $testFilePath

            Should -Not -Invoke Write-Warning
        }
    }

    Context "When using an azure profile" {
        It "Calls the azure signing script with correct parameters" {
            $testFilePath = "files\test.exe"
            $testPathCmdlet = Get-Command Test-Path -CommandType Cmdlet
            Mock Test-Path {
                param(
                    [string[]]$Path
                )

                if ($Path -contains $testFilePath) {
                    return $true
                }

                return & $testPathCmdlet -Path $Path
            }

            Export-SignedExecutable -ProfileName "azureProfile" -Files $testFilePath

            $capturedSignToolArgs = $testSession.GetCapturedLines()
            $capturedCommand = $capturedSignToolArgs[0]

            $capturedCommand | Should -Be $testLocalProfile.signToolPath
            $capturedSignToolArgs | Should -Contain $testFilePath

            Should -Not -Invoke Write-Warning
        }
    }
}
