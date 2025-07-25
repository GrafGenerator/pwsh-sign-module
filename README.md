# SignModule

[![CI](https://github.com/GrafGenerator/pwsh-sign-module/actions/workflows/ci.yml/badge.svg)](https://github.com/GrafGenerator/pwsh-sign-module/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/SignModule?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/SignModule)
[![License](https://img.shields.io/github/license/GrafGenerator/pwsh-sign-module)](https://github.com/GrafGenerator/pwsh-sign-module/blob/main/LICENSE)

A comprehensive PowerShell module for managing code signing profiles and performing signing operations on executable files. Supports both local certificate signing and Azure Key Vault integration for secure, scalable code signing workflows.

## 🚀 Features

- **Profile Management**: Create, update, and manage multiple signing profiles
- **Local Certificate Signing**: Sign with certificates stored locally
- **Azure Key Vault Integration**: Secure signing using Azure Key Vault certificates
- **Batch Processing**: Sign multiple files with pipeline support
- **Secure Storage**: Encrypted storage of sensitive information using PowerShell SecureString
- **Comprehensive Testing**: Full test suite with Pester
- **CI/CD Ready**: GitHub Actions workflow included

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands Reference](#commands-reference)
- [Profile Types](#profile-types)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 📦 Installation

### Option 1: PowerShell Gallery (Recommended)
```powershell
Install-Module -Name SignModule -Scope CurrentUser
Import-Module SignModule
```

### Option 2: Manual Installation
1. Download or clone this repository
2. Copy the module folder to one of your PowerShell module paths:
   ```powershell
   $env:PSModulePath -split ';'
   ```
3. Import the module:
   ```powershell
   Import-Module SignModule
   ```

### Verify Installation
```powershell
Get-Command -Module SignModule
```

## ⚡ Quick Start

### 1. Create a Local Signing Profile
```powershell
# Create a new local certificate profile
Add-SignProfile -ProfileName "MyLocalCert"
# Follow the interactive prompts to configure your certificate
```

### 2. Sign Your First Executable
```powershell
# Sign a single file
Export-SignedExecutable -ProfileName "MyLocalCert" -Files "C:\MyApp\MyApp.exe"

# Sign multiple files
Export-SignedExecutable -ProfileName "MyLocalCert" -Files @("App1.exe", "App2.exe")
```

### 3. Pipeline Support
```powershell
# Sign all executables in a directory
Get-ChildItem "C:\MyApps\*.exe" | Export-SignedExecutable -ProfileName "MyLocalCert"
```

## 📚 Commands Reference

### Core Commands

| Command | Description | Documentation |
|---------|-------------|---------------|
| `Add-SignProfile` | Creates a new signing profile | [📖 Details](#add-signprofile) |
| `Update-SignProfile` | Updates profile credentials | [📖 Details](#update-signprofile) |
| `Remove-SignProfile` | Removes a signing profile | [📖 Details](#remove-signprofile) |
| `Clear-SignProfiles` | Clears all profiles | [📖 Details](#clear-signprofiles) |
| `Export-SignedExecutable` | Signs executable files | [📖 Details](#export-signedexecutable) |

### Add-SignProfile

Creates a new signing profile with the specified name.

**Syntax:**
```powershell
Add-SignProfile [-ProfileName] <String> [[-ProfilePath] <String>] [<CommonParameters>]
```

**Parameters:**
- `ProfileName` (Required): Name for the new profile
- `ProfilePath` (Optional): Path to existing profile JSON file

**Examples:**
```powershell
# Create new profile interactively
Add-SignProfile -ProfileName "Production"

# Import existing profile
Add-SignProfile -ProfileName "Staging" -ProfilePath "C:\Certs\staging-profile.json"
```

### Update-SignProfile

Updates secure inputs (passwords/secrets) for an existing profile.

**Syntax:**
```powershell
Update-SignProfile [-ProfileName] <String> [<CommonParameters>]
```

**Examples:**
```powershell
# Update certificate password
Update-SignProfile -ProfileName "Production"
```

### Remove-SignProfile

Removes a profile from configuration.

**Syntax:**
```powershell
Remove-SignProfile [-ProfileName] <String> [-RemoveFile] [<CommonParameters>]
```

**Parameters:**
- `ProfileName` (Required): Name of profile to remove
- `RemoveFile` (Optional): Also delete the profile JSON file

**Examples:**
```powershell
# Remove profile from config only
Remove-SignProfile -ProfileName "OldProfile"

# Remove profile and delete file
Remove-SignProfile -ProfileName "OldProfile" -RemoveFile
```

### Clear-SignProfiles

Clears all profiles from configuration.

**Syntax:**
```powershell
Clear-SignProfiles [-RemoveFiles] [<CommonParameters>]
```

**Examples:**
```powershell
# Clear all profiles from config
Clear-SignProfiles

# Clear all profiles and delete files
Clear-SignProfiles -RemoveFiles
```

### Export-SignedExecutable

Signs executable files using the specified profile.

**Syntax:**
```powershell
Export-SignedExecutable [-ProfileName] <String> [-Files] <String[]> [<CommonParameters>]
```

**Parameters:**
- `ProfileName` (Required): Name of signing profile to use
- `Files` (Required): Array of file paths to sign

**Examples:**
```powershell
# Sign single file
Export-SignedExecutable -ProfileName "Prod" -Files "MyApp.exe"

# Sign multiple files
Export-SignedExecutable -ProfileName "Prod" -Files @("App1.exe", "App2.exe")

# Pipeline usage
Get-ChildItem "*.exe" | Export-SignedExecutable -ProfileName "Prod"
```

## 🔧 Profile Types

### Local Certificate Profile

Uses certificates stored locally on the machine.

**Required Information:**
- **Signing Tool Path**: Path to `signtool.exe` (usually in Windows SDK)
- **Certificate Path**: Path to certificate file (.pfx, .p12)
- **Certificate Password**: Password for the certificate (stored securely)
- **Timestamp URL**: Timestamp server URL (optional but recommended)

**Example Profile Structure:**
```json
{
  "type": "local",
  "signingToolPath": "C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.22621.0\\x64\\signtool.exe",
  "certificatePath": "C:\\Certificates\\MyCert.pfx",
  "timestampUrl": "http://timestamp.digicert.com"
}
```

### Azure Key Vault Profile

Uses certificates stored in Azure Key Vault for enhanced security.

**Required Information:**
- **Azure SignTool Path**: Path to `azuresigntool.exe`
- **Key Vault URL**: Your Azure Key Vault URL
- **Tenant ID**: Azure AD tenant ID
- **Client ID**: Service principal client ID
- **Client Secret**: Service principal secret (stored securely)
- **Certificate Name**: Name of certificate in Key Vault

**Example Profile Structure:**
```json
{
  "type": "azure",
  "azureSignToolPath": "C:\\Tools\\azuresigntool.exe",
  "keyVaultUrl": "https://myvault.vault.azure.net/",
  "tenantId": "12345678-1234-1234-1234-123456789012",
  "clientId": "87654321-4321-4321-4321-210987654321",
  "certificateName": "CodeSigningCert"
}
```

## 💡 Usage Examples

### Basic Signing Workflow

```powershell
# 1. Import the module
Import-Module SignModule

# 2. Create a signing profile
Add-SignProfile -ProfileName "MyCompany"
# Follow prompts to configure certificate details

# 3. Sign your applications
Export-SignedExecutable -ProfileName "MyCompany" -Files "MyApp.exe"
```

### CI/CD Integration

```powershell
# Azure DevOps Pipeline example
# Store certificate as secure file and reference in pipeline

# PowerShell task in pipeline
Import-Module SignModule
Add-SignProfile -ProfileName "CI" -ProfilePath "$(Agent.TempDirectory)\signing-profile.json"
Get-ChildItem "$(Build.ArtifactStagingDirectory)\*.exe" | 
    Export-SignedExecutable -ProfileName "CI"
```

### Profile Management

```powershell
# List all configured profiles
Get-Content "$env:PSModulePath\SignModule\config.json" | ConvertFrom-Json | 
    Select-Object -ExpandProperty profiles | 
    ForEach-Object { $_.PSObject.Properties.Name }

# Update certificate password
Update-SignProfile -ProfileName "Production"

# Remove old profile
Remove-SignProfile -ProfileName "OldCert" -RemoveFile
```

## ⚙️ Configuration

### Configuration Files Location

SignModule stores configuration in:
```
%PSModulePath%\SignModule\config.json
%PSModulePath%\SignModule\profiles\*.json
```

### Security Considerations

- **Passwords**: Stored as PowerShell SecureString objects
- **Profile Files**: Contains non-sensitive configuration only
- **Permissions**: Configuration directory has restricted access
- **Secrets**: Never stored in plain text

## 🔍 Troubleshooting

Please read the [Troubleshooting Guide](docs/Troubleshooting.md) for details.

## 🤝 Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE) file for details.