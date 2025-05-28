using namespace System.Security
using namespace System.IO

function Save-SecureInput {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [Parameter(Mandatory)]
        [string]$InputAlias,

        [Parameter(Mandatory)]
        [SecureString]$SecureInput
    )
    Test-ProfileName -ProfileName $ProfileName

    $profileFolderPath = [FileInfo]::new($ProfilePath).Directory.FullName;
    $secretFileName = "$ProfileName-$InputAlias";
    $secretFilePath = Join-Path $profileFolderPath $secretFileName;

    $SecureInput | ConvertFrom-SecureString | Set-Content $secretFilePath
}

function Get-SecureInput {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter(Mandatory)]
        [string]$ProfilePath,
    
        [Parameter(Mandatory)]
        [string]$InputAlias
    )
    Test-ProfileName -ProfileName $ProfileName

    $profileFolderPath = [FileInfo]::new($ProfilePath).Directory.FullName;
    $secretFileName = "$ProfileName-$InputAlias";
    $secretFilePath = Join-Path $profileFolderPath $secretFileName;

    if (Test-Path $secretFilePath) {
        Get-Content $secretFilePath | ConvertTo-SecureString
    }
}
