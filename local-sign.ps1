param(
    [Parameter(Mandatory)]
    [string]$ProfilePath,
    
    [Parameter(Mandatory)]
    [string[]]$Files
)

$signingProfile = Get-Content $ProfilePath | ConvertFrom-Json

if ($signingProfile.type -ne 'local') {
    throw "Profile is not a local signing profile"
}

$securePassword = Get-Content "$($ProfilePath -replace '\.json$')-pwd" | ConvertTo-SecureString

. $PSScriptRoot\common.ps1
$password = Convert-SecureStringToPlainText -SecureString $securePassword

foreach ($file in $Files) {
    & $signingProfile.signToolPath sign /f $signingProfile.certificatePath /p $password $file
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign file: $file"
    }
    else {
        Write-Output "Successfully signed file: $file"
    }
}
