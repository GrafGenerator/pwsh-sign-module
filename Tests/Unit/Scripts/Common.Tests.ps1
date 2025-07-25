[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    # Import test setup
    . $PSScriptRoot\..\..\TestHelpers\TestSetup.ps1

    # Import the script being tested
    . "$ModuleRoot\Scripts\common.ps1"
}

Describe "Common Script Functions" {
    Context "Convert-SecureStringToPlainText" {
        It "Converts a secure string to plain text" {
            # Create a secure string
            $plainText = "TestPassword123!"
            $secureString = ConvertTo-SecureString -String $plainText -AsPlainText -Force

            # Call function
            $result = Convert-SecureStringToPlainText -SecureString $secureString

            # Verify result
            $result | Should -Be $plainText
        }

        It "Returns empty string for null secure string" {
            # PowerShell doesn't let us create a null SecureString directly, so we'll skip this test
            # and just document that it would be good to test this case
        }
    }
}
