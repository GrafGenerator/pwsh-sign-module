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
    $signCommand = @(
        "sign",
        "/f", $signingProfile.certificatePath,
        "/p", $password
    )
    
    # Add additional parameters if specified
    if ($signingProfile.PSObject.Properties.Name -contains "additionalParams" -and -not [string]::IsNullOrWhiteSpace($signingProfile.additionalParams)) {
        Write-Output "Using additional parameters: $($signingProfile.additionalParams)"
        $additionalParamsArray = $signingProfile.additionalParams -split ' '
        $signCommand += $additionalParamsArray
    }
    
    # Add the file to sign
    $signCommand += $file
    
    & $signingProfile.signToolPath $signCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign file: $file"
    }
    else {
        Write-Output "Successfully signed file: $file"
    }
}
