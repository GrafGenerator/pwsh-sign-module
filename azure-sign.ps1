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
$clientSecretBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
try {
    $clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($clientSecretBstr)
}
finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($clientSecretBstr) | Out-Null
}

foreach ($file in $Files) {
    & $signingProfile.signToolPath sign `
        --azure-key-vault-url $signingProfile.keyVaultUrl `
        --azure-key-vault-certificate $signingProfile.certificateName `
        --azure-tenant-id $signingProfile.tenantId `
        --azure-client-id $signingProfile.clientId `
        --azure-client-secret $clientSecret `
        $file

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign file: $file"
    }
    else {
        Write-Output "Successfully signed file: $file"
    }
}
