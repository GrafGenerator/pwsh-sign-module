@{
    RootModule = 'SignModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = '2c6f8b6f-7f27-4908-8e8f-5a2f5b7c1eb6'
    Author = 'Nikita Ivanov'
    Description = 'Module for managing signing profiles and performing signing operations on EXE files'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Add-SignProfile',
        'Update-SignProfile',
        'Remove-SignProfile',
        'Clear-SignProfiles',
        'Export-SignedExecutable'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Signing', 'CodeSigning', 'Azure', 'Certificate', 'AzureKeyVault', 'Secret', 'Pipeline', 'AzureDevOps', 'PipelineSigning', 'AzureKeyVaultSigning')
            LicenseUri = 'https://github.com/GrafGenerator/pwsh-sign-module/blob/main/LICENSE'
            ProjectUri = 'https://github.com/GrafGenerator/pwsh-sign-module'
        }
    }
}
