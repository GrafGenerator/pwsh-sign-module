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

        $scriptPath = Join-Path $PSScriptRoot "..\\Scripts\\$(if ($signingProfile.type -eq 'local') { 'local-sign.ps1' } else { 'azure-sign.ps1' })"
        if (-not (Test-Path $scriptPath)) {
            throw "Signing script not found: $scriptPath"
        }
    }

    process {
        foreach ($file in $Files) {
            if (-not (Test-Path $file)) {
                Write-Error "File not found: $file"
                continue
            }
            if ([System.IO.Path]::GetExtension($file) -ne '.exe') {
                Write-Error "File is not an executable: $file"
                continue
            }
        }

        & $scriptPath -ProfilePath $profilePath -Files $Files
    }
}
