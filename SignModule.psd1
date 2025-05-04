@{
    RootModule = 'SignModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = '1234e123-e123-1234-1234-123456789012'
    Author = 'SignModule Author'
    Description = 'Module for managing signing profiles and performing signing operations on exe files'
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
            Tags = @('Signing', 'CodeSigning', 'Azure', 'Certificate')
        }
    }
}
