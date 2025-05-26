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
    & $signingProfile.signToolPath sign `
        --azure-key-vault-url $signingProfile.keyVaultUrl `
        --azure-key-vault-certificate $signingProfile.certificateName `
        --azure-key-vault-tenant-id $signingProfile.tenantId `
        --azure-key-vault-client-id $signingProfile.clientId `
        --azure-key-vault-client-secret $clientSecret `
        $file

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign file: $file"
    }
    else {
        Write-Output "Successfully signed file: $file"
    }
}
