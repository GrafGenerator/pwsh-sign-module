<#
.SYNOPSIS
Signs executable files using a specified signing profile.

.DESCRIPTION
The Export-SignedExecutable function signs one or more executable files using the configuration
from a previously created signing profile. It supports both local certificate signing and
Azure Key Vault signing, automatically selecting the appropriate signing method based on the
profile type. The function validates file paths and extensions before attempting to sign.

.PARAMETER ProfileName
Specifies the name of the signing profile to use for signing operations. The profile must
exist and be properly configured. Use Add-SignProfile to create profiles.

.PARAMETER Files
Specifies an array of file paths to sign. Files must exist and have the .exe extension.
This parameter accepts pipeline input, allowing you to pipe file objects from other commands.

.INPUTS
System.String[]. You can pipe file paths to Export-SignedExecutable.

.OUTPUTS
None. This function does not return objects but signs the specified files.

.EXAMPLE
Export-SignedExecutable -ProfileName "Production" -Files "C:\MyApp\MyApp.exe"

Signs a single executable file using the "Production" profile.

.EXAMPLE
Export-SignedExecutable -ProfileName "Production" -Files @("App1.exe", "App2.exe", "App3.exe")

Signs multiple executable files using the "Production" profile.

.EXAMPLE
Get-ChildItem "C:\Build\Output\*.exe" | Export-SignedExecutable -ProfileName "Production"

Uses pipeline input to sign all .exe files in the specified directory.

.EXAMPLE
$filesToSign = Get-ChildItem "C:\MyApps" -Recurse -Filter "*.exe"
$filesToSign | Export-SignedExecutable -ProfileName "LocalCert"

Finds all executable files recursively in a directory tree and signs them using a local certificate profile.

.EXAMPLE
# Sign files with error handling
try {
    Export-SignedExecutable -ProfileName "AzureKV" -Files "MyApp.exe"
    Write-Host "Signing completed successfully"
}
catch {
    Write-Error "Signing failed: $($_.Exception.Message)"
}

Example with error handling to catch signing failures.

.EXAMPLE
# Batch signing with filtering
Get-ChildItem "C:\Build" -Recurse | 
    Where-Object { $_.Extension -eq '.exe' -and $_.Length -gt 1MB } |
    Export-SignedExecutable -ProfileName "Production"

Signs only executable files larger than 1MB from a build directory.

.NOTES
File Name      : Export-SignedExecutable.ps1
Author         : GrafGenerator
Prerequisite   : PowerShell 5.1 or later
Copyright 2025 : GrafGenerator

This function requires:
- A valid signing profile created with Add-SignProfile
- Appropriate signing tools (SignTool.exe for local, AzureSignTool.exe for Azure)
- Valid certificates accessible through the configured profile
- Files must have .exe extension and exist on the file system

The function will skip files that don't exist or don't have the correct extension,
logging warnings for each skipped file.

.LINK
Add-SignProfile

.LINK
Update-SignProfile

.LINK
Remove-SignProfile

.LINK
https://github.com/GrafGenerator/pwsh-sign-module
#>
function Export-SignedExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Files
    )

    begin {
        $config = Get-Config
        if (-not $config.profiles.ContainsKey($ProfileName)) {
            throw "Profile '$ProfileName' not found"
        }

        $profilePath = $config.profiles[$ProfileName].path
        $signingProfile = Get-Content $profilePath | ConvertFrom-Json

        $scriptName = if ($signingProfile.type -eq 'local') { 'local-sign.ps1' } else { 'azure-sign.ps1' }
        $scriptPath = Join-Path $PSScriptRoot "..\\Scripts\\$scriptName"
        if (-not (Test-Path $scriptPath)) {
            throw "Signing script not found: $scriptPath"
        }
    }

    process {
        foreach ($file in $Files) {
            if (-not (Test-Path $file)) {
                Write-Warning "File not found: $file"
                continue
            }
            if ([System.IO.Path]::GetExtension($file) -ne '.exe') {
                Write-Warning "File is not an executable: $file"
                continue
            }
        }

        & $scriptPath -ProfilePath $profilePath -Files $Files
    }
}
