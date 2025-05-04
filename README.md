# SignModule

PowerShell module for managing code signing profiles and performing signing operations on executable files.

## Installation

1. Copy the module folder to one of your PowerShell module paths
2. Import the module:
```powershell
Import-Module SignModule
```

## Commands

### Add-SignProfile
Creates a new signing profile with specified name. Can either use an existing profile file or create a new one by providing profile information.

### Update-SignProfile
Updates secure inputs (password/client secret) for an existing profile.

### Remove-SignProfile
Removes a profile from configuration. Can optionally remove the profile file.

### Clear-SignProfiles
Clears all profiles from configuration. Can optionally remove all profile files.

### Export-SignedExecutable
Signs executable files using the specified profile. Supports both local certificate and Azure Key Vault signing.

## Profile Types

### Local
- Uses local certificate for signing
- Requires:
  - Path to signing tool
  - Path to certificate
  - Certificate password

### Azure
- Uses Azure Key Vault certificate for signing
- Requires:
  - Path to Azure signing tool
  - Key Vault URL
  - Tenant ID
  - Client ID
  - Client Secret
  - Certificate name
