param(
    [Parameter(Mandatory)]
    [string]$ProfilePath,
    
    [Parameter(Mandatory)]
    [string[]]$Files
)

$profile = Get-Content $ProfilePath | ConvertFrom-Json

if ($profile.type -ne 'local') {
    throw "Profile is not a local signing profile"
}

$securePassword = Get-Content "$($ProfilePath -replace '\.json$')-pwd" | ConvertTo-SecureString
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
)

foreach ($file in $Files) {
    & $profile.signToolPath sign /f $profile.certificatePath /p $password $file
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign file: $file"
    }
    else {
        Write-Output "Successfully signed file: $file"
    }
}
