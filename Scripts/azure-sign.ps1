param(
    [Parameter(Mandatory)]
    [string]$ProfilePath,
    
    [Parameter(Mandatory)]
    [string[]]$Files
)

$signingProfile = Get-Content $ProfilePath | ConvertFrom-Json

if ($signingProfile.type -ne 'azure') {
    throw "Profile is not an Azure signing profile"
}

$secureSecret = Get-Content "$($ProfilePath -replace '\.json$')-kvs" | ConvertTo-SecureString

. $PSScriptRoot\common.ps1
$clientSecret = Convert-SecureStringToPlainText -SecureString $secureSecret

foreach ($file in $Files) {
    $signCommand = @(
        "sign",
        "--azure-key-vault-url", $signingProfile.keyVaultUrl,
        "--azure-key-vault-certificate", $signingProfile.certificateName,
        "--azure-key-vault-tenant-id", $signingProfile.tenantId,
        "--azure-key-vault-client-id", $signingProfile.clientId,
        "--azure-key-vault-client-secret", $clientSecret
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
