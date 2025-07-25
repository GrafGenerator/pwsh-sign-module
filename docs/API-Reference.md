# SignModule API Reference

This document provides detailed API reference for all SignModule functions, including parameters, examples, and usage patterns.

## Table of Contents

- [Module Overview](#module-overview)
- [Public Functions](#public-functions)
  - [Add-SignProfile](#add-signprofile)
  - [Update-SignProfile](#update-signprofile)
  - [Remove-SignProfile](#remove-signprofile)
  - [Clear-SignProfiles](#clear-signprofiles)
  - [Export-SignedExecutable](#export-signedexecutable)
- [Profile Configuration](#profile-configuration)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Module Overview

**SignModule** is a PowerShell module designed for managing code signing profiles and performing signing operations on executable files. It provides a unified interface for both local certificate signing and Azure Key Vault integration.

### Module Information
- **Name**: SignModule
- **Version**: 1.0.0
- **Author**: GrafGenerator
- **PowerShell Version**: 5.1+
- **Platform**: Windows

### Installation
```powershell
Install-Module -Name SignModule -Scope CurrentUser
Import-Module SignModule
```

## Public Functions

### Add-SignProfile

Creates a new code signing profile for use with SignModule.

#### Syntax
```powershell
Add-SignProfile [-ProfileName] <String> [[-ProfilePath] <String>] [<CommonParameters>]
```

#### Parameters

| Parameter | Type | Required | Pipeline Input | Description |
|-----------|------|----------|----------------|-------------|
| ProfileName | String | Yes | No | Name for the new signing profile |
| ProfilePath | String | No | No | Path to existing profile JSON file |

#### Parameter Details

**ProfileName**
- **Type**: String
- **Required**: Yes
- **Position**: 1
- **Validation**: Must be unique, cannot contain invalid filename characters
- **Description**: Specifies the name for the new signing profile. This name will be used to reference the profile in other SignModule commands.

**ProfilePath**
- **Type**: String
- **Required**: No
- **Position**: 2
- **Description**: Optional path to an existing profile JSON file to import. If not specified, the function will prompt for profile configuration details interactively.

#### Examples

**Example 1: Interactive Profile Creation**
```powershell
Add-SignProfile -ProfileName "Production"
```
Creates a new profile named "Production" using interactive prompts.

**Example 2: Import Existing Profile**
```powershell
Add-SignProfile -ProfileName "Staging" -ProfilePath "C:\Certs\staging-profile.json"
```
Creates a profile by importing from an existing JSON file.

**Example 3: Local Certificate Profile**
```powershell
Add-SignProfile -ProfileName "LocalCert"
# Interactive prompts will ask for:
# - Profile type: local
# - Signing tool path: C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe
# - Certificate path: C:\Certificates\MyCert.pfx
# - Certificate password: (secure input)
# - Timestamp URL: http://timestamp.digicert.com
```

**Example 4: Azure Key Vault Profile**
```powershell
Add-SignProfile -ProfileName "AzureKV"
# Interactive prompts will ask for:
# - Profile type: azure
# - Azure SignTool path: C:\Tools\azuresigntool.exe
# - Key Vault URL: https://myvault.vault.azure.net/
# - Tenant ID: 12345678-1234-1234-1234-123456789012
# - Client ID: 87654321-4321-4321-4321-210987654321
# - Client Secret: (secure input)
# - Certificate Name: CodeSigningCert
```

#### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| "Profile 'X' already exists" | Profile name is already in use | Use a different name or remove existing profile |
| "Invalid profile name" | Profile name contains invalid characters | Use alphanumeric characters and common symbols |
| "Profile file not found" | Specified ProfilePath doesn't exist | Verify file path and permissions |
| "Invalid profile format" | JSON file format is incorrect | Validate JSON structure |

---

### Update-SignProfile

Updates secure inputs (passwords/secrets) for an existing profile.

#### Syntax
```powershell
Update-SignProfile [-ProfileName] <String> [<CommonParameters>]
```

#### Parameters

| Parameter | Type | Required | Pipeline Input | Description |
|-----------|------|----------|----------------|-------------|
| ProfileName | String | Yes | No | Name of the profile to update |

#### Parameter Details

**ProfileName**
- **Type**: String
- **Required**: Yes
- **Position**: 1
- **Description**: Specifies the name of an existing signing profile to update. The profile must exist in the configuration.

#### Examples

**Example 1: Update Certificate Password**
```powershell
Update-SignProfile -ProfileName "Production"
```
Updates the certificate password for a local certificate profile.

**Example 2: Update Azure Client Secret**
```powershell
Update-SignProfile -ProfileName "AzureKV"
```
Updates the client secret for an Azure Key Vault profile.

#### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| "Profile 'X' not found" | Profile doesn't exist | Verify profile name or create the profile |
| "Access denied" | Insufficient permissions | Run as administrator or check file permissions |

---

### Remove-SignProfile

Removes a profile from configuration and optionally deletes the profile file.

#### Syntax
```powershell
Remove-SignProfile [-ProfileName] <String> [-RemoveFile] [<CommonParameters>]
```

#### Parameters

| Parameter | Type | Required | Pipeline Input | Description |
|-----------|------|----------|----------------|-------------|
| ProfileName | String | Yes | No | Name of the profile to remove |
| RemoveFile | Switch | No | No | Also delete the profile JSON file |

#### Parameter Details

**ProfileName**
- **Type**: String
- **Required**: Yes
- **Position**: 1
- **Description**: Specifies the name of the signing profile to remove from configuration.

**RemoveFile**
- **Type**: Switch
- **Required**: No
- **Description**: When specified, also deletes the profile JSON file from disk. By default, only removes the profile from configuration.

#### Examples

**Example 1: Remove Profile from Configuration**
```powershell
Remove-SignProfile -ProfileName "OldProfile"
```
Removes the profile from configuration but keeps the JSON file.

**Example 2: Remove Profile and File**
```powershell
Remove-SignProfile -ProfileName "OldProfile" -RemoveFile
```
Removes the profile from configuration and deletes the JSON file.

**Example 3: Batch Removal**
```powershell
@("Profile1", "Profile2", "Profile3") | ForEach-Object {
    Remove-SignProfile -ProfileName $_ -RemoveFile
}
```
Removes multiple profiles and their files.

#### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| "Profile 'X' not found" | Profile doesn't exist | Verify profile name |
| "Access denied" | Cannot delete file | Check file permissions |

---

### Clear-SignProfiles

Clears all profiles from configuration and optionally removes all profile files.

#### Syntax
```powershell
Clear-SignProfiles [-RemoveFiles] [<CommonParameters>]
```

#### Parameters

| Parameter | Type | Required | Pipeline Input | Description |
|-----------|------|----------|----------------|-------------|
| RemoveFiles | Switch | No | No | Also delete all profile JSON files |

#### Parameter Details

**RemoveFiles**
- **Type**: Switch
- **Required**: No
- **Description**: When specified, also deletes all profile JSON files from disk. By default, only clears the configuration.

#### Examples

**Example 1: Clear Configuration Only**
```powershell
Clear-SignProfiles
```
Clears all profiles from configuration but keeps JSON files.

**Example 2: Clear Everything**
```powershell
Clear-SignProfiles -RemoveFiles
```
Clears all profiles and deletes all JSON files.

**Example 3: Reset with Confirmation**
```powershell
if (Read-Host "Clear all profiles? (y/N)" -eq 'y') {
    Clear-SignProfiles -RemoveFiles
    Write-Host "All profiles cleared"
}
```
Prompts for confirmation before clearing.

#### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| "Access denied" | Cannot delete files | Check directory permissions |

---

### Export-SignedExecutable

Signs executable files using a specified signing profile.

#### Syntax
```powershell
Export-SignedExecutable [-ProfileName] <String> [-Files] <String[]> [<CommonParameters>]
```

#### Parameters

| Parameter | Type | Required | Pipeline Input | Description |
|-----------|------|----------|----------------|-------------|
| ProfileName | String | Yes | No | Name of the signing profile to use |
| Files | String[] | Yes | Yes (ByValue) | Array of file paths to sign |

#### Parameter Details

**ProfileName**
- **Type**: String
- **Required**: Yes
- **Position**: 1
- **Description**: Specifies the name of the signing profile to use for signing operations. The profile must exist and be properly configured.

**Files**
- **Type**: String[]
- **Required**: Yes
- **Position**: 2
- **Pipeline Input**: Yes (ByValue)
- **Description**: Specifies an array of file paths to sign. Files must exist and have the .exe extension. Accepts pipeline input.

#### Examples

**Example 1: Sign Single File**
```powershell
Export-SignedExecutable -ProfileName "Production" -Files "C:\MyApp\MyApp.exe"
```
Signs a single executable file.

**Example 2: Sign Multiple Files**
```powershell
Export-SignedExecutable -ProfileName "Production" -Files @("App1.exe", "App2.exe", "App3.exe")
```
Signs multiple executable files.

**Example 3: Pipeline Input**
```powershell
Get-ChildItem "C:\Build\Output\*.exe" | Export-SignedExecutable -ProfileName "Production"
```
Uses pipeline to sign all .exe files in a directory.

**Example 4: Recursive Signing**
```powershell
Get-ChildItem "C:\MyApps" -Recurse -Filter "*.exe" | 
    Export-SignedExecutable -ProfileName "LocalCert"
```
Recursively finds and signs all executable files.

**Example 5: Conditional Signing**
```powershell
Get-ChildItem "C:\Build" -Recurse | 
    Where-Object { $_.Extension -eq '.exe' -and $_.Length -gt 1MB } |
    Export-SignedExecutable -ProfileName "Production"
```
Signs only executable files larger than 1MB.

**Example 6: Error Handling**
```powershell
try {
    Export-SignedExecutable -ProfileName "AzureKV" -Files "MyApp.exe"
    Write-Host "Signing completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Signing failed: $($_.Exception.Message)"
    exit 1
}
```
Implements error handling for signing operations.

**Example 7: Batch Processing with Progress**
```powershell
$files = Get-ChildItem "C:\Build\*.exe"
$total = $files.Count
$current = 0

$files | ForEach-Object {
    $current++
    Write-Progress -Activity "Signing Files" -Status "Processing $($_.Name)" -PercentComplete (($current / $total) * 100)
    $_ | Export-SignedExecutable -ProfileName "Production"
}
Write-Progress -Activity "Signing Files" -Completed
```
Shows progress while signing multiple files.

#### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| "Profile 'X' not found" | Profile doesn't exist | Create the profile or verify name |
| "File not found: X" | File doesn't exist | Verify file path |
| "File is not an executable: X" | File doesn't have .exe extension | Only .exe files are supported |
| "Signing script not found" | Missing signing script | Verify module installation |
| "SignTool.exe not found" | Missing signing tool | Install Windows SDK |
| "Certificate not found" | Certificate file missing | Verify certificate path |
| "Invalid certificate password" | Wrong password | Update profile with correct password |

---

## Profile Configuration

### Profile Structure

Profiles are stored as JSON files in `%PSModulePath%\SignModule\profiles\` with the following structure:

#### Local Certificate Profile
```json
{
  "type": "local",
  "signingToolPath": "C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.22621.0\\x64\\signtool.exe",
  "certificatePath": "C:\\Certificates\\MyCert.pfx",
  "timestampUrl": "http://timestamp.digicert.com"
}
```

#### Azure Key Vault Profile
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

### Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| config.json | %PSModulePath%\SignModule\ | Main configuration with profile references |
| *.json | %PSModulePath%\SignModule\profiles\ | Individual profile configurations |
| *-pwd | %PSModulePath%\SignModule\profiles\ | Encrypted password files |
| *-kvs | %PSModulePath%\SignModule\profiles\ | Encrypted Key Vault secrets |

### Security Model

- **Passwords**: Stored as PowerShell SecureString in separate files
- **Secrets**: Encrypted using Windows Data Protection API (DPAPI)
- **Configuration**: Non-sensitive data only in JSON files
- **Access**: Configuration directory has restricted permissions

---

## Error Handling

### Common Error Patterns

#### Profile Errors
```powershell
try {
    Add-SignProfile -ProfileName "Test"
}
catch [System.InvalidOperationException] {
    Write-Warning "Profile already exists"
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
}
```

#### Signing Errors
```powershell
try {
    Export-SignedExecutable -ProfileName "Prod" -Files "app.exe"
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File or signing tool not found"
}
catch [System.UnauthorizedAccessException] {
    Write-Error "Access denied - run as administrator"
}
catch {
    Write-Error "Signing failed: $($_.Exception.Message)"
}
```

### Error Categories

| Category | Description | Common Causes |
|----------|-------------|---------------|
| Configuration | Profile management errors | Missing profiles, invalid names |
| File System | File access errors | Missing files, permissions |
| Certificate | Certificate-related errors | Invalid certificates, wrong passwords |
| Network | Azure/timestamp server errors | Connectivity issues, invalid URLs |
| Tool | Signing tool errors | Missing tools, invalid parameters |

---

### Example Workflow

```powershell
# 1. Setup
Import-Module SignModule

# 2. Create profile (one-time)
Add-SignProfile -ProfileName "Production"

# 3. Batch signing with error handling
$files = Get-ChildItem "C:\Build\*.exe"
$signed = @()
$failed = @()

foreach ($file in $files) {
    try {
        Export-SignedExecutable -ProfileName "Production" -Files $file.FullName
        $signed += $file.Name
        Write-Host "✓ Signed: $($file.Name)" -ForegroundColor Green
    }
    catch {
        $failed += @{ File = $file.Name; Error = $_.Exception.Message }
        Write-Warning "✗ Failed: $($file.Name) - $($_.Exception.Message)"
    }
}

# 4. Report results
Write-Host "`nSigning Summary:" -ForegroundColor Cyan
Write-Host "  Signed: $($signed.Count) files" -ForegroundColor Green
Write-Host "  Failed: $($failed.Count) files" -ForegroundColor Red

if ($failed.Count -gt 0) {
    Write-Host "`nFailed files:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $($_.File): $($_.Error)" }
}
```

---

*For more examples and advanced usage patterns, see the [main README](../README.md) and [contributing guide](../CONTRIBUTING.md).*
