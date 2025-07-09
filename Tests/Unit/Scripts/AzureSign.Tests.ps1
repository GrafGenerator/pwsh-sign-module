BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1
    
    . $script:ScriptsPath\common.ps1

    Initialize-TestEnvironment

    # Create test profile
    $script:TestProfilePath = Join-Path $script:TestProfilesDir "testAzureProfile.json"

    $testSecret = "MockSecureClientSecret"
    $testSecretSecureString = ConvertTo-SecureString -String $testSecret -AsPlainText -Force

    # Create test client secret file
    $testSecretPath = Join-Path $script:TestProfilesDir "testAzureProfile-kvs"
    $testSecret | Set-Content $testSecretPath

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

Describe "Azure-Sign Script" {
    BeforeEach {
        $tempSignResultFile = Join-Path $script:TempPath "testLocalProfile-signResult-$(New-Guid).txt"
    
        $additionalParam1 = "-tr"
        $additionalParam2 = "http://timestamp.test"
        
        # Create test profile
        $testProfileData = @{
            type = "azure"
            signToolPath = $script:TestSignToolPath
            keyVaultUrl = "https://testvault.vault.azure.net/"
            tenantId = "00000000-0000-0000-0000-000000000000"
            clientId = "11111111-1111-1111-1111-111111111111"
            certificateName = "TestCert"
            additionalParams = "$additionalParam1 $additionalParam2 --testOutFile $tempSignResultFile"
        }
        $testProfileData | ConvertTo-Json | Set-Content $script:TestProfilePath

        

        # Set up the test for each context
        Mock Convert-SecureStringToPlainText {
            param(
                [System.Security.SecureString]$SecureString
            )
            return $testSecret
        }

        Mock ConvertTo-SecureString {
            return $testSecretSecureString
        }
    }
    
    AfterEach {
        Remove-Item $tempSignResultFile -ErrorAction SilentlyContinue
    }

    Context "Parameter validation" {
        It "Throws if profile is not an azure profile" {
            # Create a local profile for testing
            $localProfilePath = Join-Path $script:TestProfilesDir "localProfile.json"
            @{
                type = "local"
                signToolPath = $script:TestSignToolPath
            } | ConvertTo-Json | Set-Content $localProfilePath
            
            # Test script with local profile - should throw
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $localProfilePath -Files $TestFile1 } | Should -Throw "*not an Azure signing profile*"
        }
    }
    
    Context "Signing a single file" {
        It "Calls the sign tool with correct parameters" {
            # Run the script
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw
            
            $capturedSignToolArgs = @()
            foreach($line in [System.IO.File]::ReadLines($tempSignResultFile)) {
                $capturedSignToolArgs += $line
            }

            $capturedCommand = $capturedSignToolArgs[0]

            # Verify SignTool.exe was called
            $capturedCommand | Should -Be $testProfileData.signToolPath

            # Verify arguments passed to SignTool.exe
            $capturedSignToolArgs | Should -Contain "sign"
            $capturedSignToolArgs | Should -Contain "--azure-key-vault-url"
            $capturedSignToolArgs | Should -Contain $testProfileData.keyVaultUrl
            $capturedSignToolArgs | Should -Contain "--azure-key-vault-certificate"
            $capturedSignToolArgs | Should -Contain $testProfileData.certificateName
            $capturedSignToolArgs | Should -Contain "--azure-key-vault-tenant-id"
            $capturedSignToolArgs | Should -Contain $testProfileData.tenantId
            $capturedSignToolArgs | Should -Contain "--azure-key-vault-client-id"
            $capturedSignToolArgs | Should -Contain $testProfileData.clientId
            $capturedSignToolArgs | Should -Contain "--azure-key-vault-client-secret"
            $capturedSignToolArgs | Should -Contain $testSecret
            $capturedSignToolArgs | Should -Contain $additionalParam1
            $capturedSignToolArgs | Should -Contain $additionalParam2
            $capturedSignToolArgs | Should -Contain $script:TestFile1

            Should -Not -Invoke Write-Error
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed*"
            }
        }
    }
    
    Context "Signing multiple files" {
        It "Processes each file in the Files array" {
            # Run the script with multiple files
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $script:TestProfilePath -Files @($script:TestFile1, $script:TestFile2) } | Should -Not -Throw
            
            $capturedSignToolArgs = @()
            foreach($line in [System.IO.File]::ReadLines($tempSignResultFile)) {
                $capturedSignToolArgs += $line
            }

            $capturedSignToolArgs | Should -Contain $script:TestFile1
            $capturedSignToolArgs | Should -Contain $script:TestFile2

            Should -Not -Invoke Write-Error
            Should -Invoke Write-Output -ParameterFilter {
                $InputObject -like "*Successfully signed*"
            }
        }
    }
    
    Context "Using additional parameters" {
        It "Includes additional parameters when specified" {
            # Run the script
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw
            
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
            { . "$ModuleRoot\Scripts\azure-sign.ps1" -ProfilePath $script:TestProfilePath -Files $script:TestFile1 } | Should -Not -Throw
            
            Should -Invoke Write-Error -ParameterFilter {
                $Message -like "*Failed to sign file*"
            }
        }
    }
}
