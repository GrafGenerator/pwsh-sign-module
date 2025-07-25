# SignModule Troubleshooting Guide

This guide helps you diagnose and resolve common issues with SignModule.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Error Messages](#error-messages)
- [Configuration Problems](#configuration-problems)
- [Certificate Issues](#certificate-issues)
- [Azure Key Vault Issues](#azure-key-vault-issues)
- [Performance Issues](#performance-issues)
- [Debug Mode](#debug-mode)
- [Getting Help](#getting-help)

## Quick Diagnostics

### Module Health Check

Run this diagnostic script to check your SignModule installation:

```powershell
# SignModule Health Check
Write-Host "SignModule Health Check" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# 1. Check module installation
Write-Host "`n1. Module Installation:" -ForegroundColor Yellow
try {
    $module = Get-Module -ListAvailable SignModule
    if ($module) {
        Write-Host "   ✓ SignModule found - Version: $($module.Version)" -ForegroundColor Green
        Import-Module SignModule -Force
        Write-Host "   ✓ Module imported successfully" -ForegroundColor Green
    } else {
        Write-Host "   ✗ SignModule not found" -ForegroundColor Red
        Write-Host "   → Install with: Install-Module SignModule" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Error importing module: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Check configuration
Write-Host "`n2. Configuration:" -ForegroundColor Yellow
$configPath = "$env:PSModulePath\SignModule"
$configFile = "$configPath\config.json"

if (Test-Path $configPath) {
    Write-Host "   ✓ Configuration directory exists: $configPath" -ForegroundColor Green
} else {
    Write-Host "   ✗ Configuration directory missing: $configPath" -ForegroundColor Red
}

if (Test-Path $configFile) {
    Write-Host "   ✓ Configuration file exists" -ForegroundColor Green
    try {
        $config = Get-Content $configFile | ConvertFrom-Json
        $profileCount = $config.profiles.PSObject.Properties.Count
        Write-Host "   ✓ Configuration valid - $profileCount profiles found" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Configuration file corrupted" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠ Configuration file not found (will be created on first use)" -ForegroundColor Yellow
}

# 3. Check commands
Write-Host "`n3. Available Commands:" -ForegroundColor Yellow
try {
    $commands = Get-Command -Module SignModule
    foreach ($cmd in $commands) {
        Write-Host "   ✓ $($cmd.Name)" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ Cannot enumerate commands" -ForegroundColor Red
}

# 4. Check signing tools
Write-Host "`n4. Signing Tools:" -ForegroundColor Yellow

# Check SignTool.exe
$signToolPaths = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe",
    "${env:ProgramFiles}\Windows Kits\10\bin\*\x64\signtool.exe",
    "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\*\bin\signtool.exe"
)

$signToolFound = $false
foreach ($path in $signToolPaths) {
    $found = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Write-Host "   ✓ SignTool.exe found: $($found.FullName)" -ForegroundColor Green
        $signToolFound = $true
        break
    }
}

if (-not $signToolFound) {
    Write-Host "   ✗ SignTool.exe not found" -ForegroundColor Red
    Write-Host "   → Install Windows SDK from: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
}

Write-Host "`nHealth check complete!" -ForegroundColor Cyan
```

### Profile Verification

Check your profiles with this script:

```powershell
# Profile Verification
$configFile = "$env:PSModulePath\SignModule\config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    Write-Host "Configured Profiles:" -ForegroundColor Cyan
    
    foreach ($profileName in $config.profiles.PSObject.Properties.Name) {
        $profilePath = $config.profiles.$profileName.path
        Write-Host "`n  Profile: $profileName" -ForegroundColor Yellow
        
        if (Test-Path $profilePath) {
            Write-Host "    ✓ Profile file exists: $profilePath" -ForegroundColor Green
            try {
                $profile = Get-Content $profilePath | ConvertFrom-Json
                Write-Host "    ✓ Type: $($profile.type)" -ForegroundColor Green
                
                if ($profile.type -eq "local") {
                    Write-Host "    ✓ Certificate: $($profile.certificatePath)" -ForegroundColor Green
                    Write-Host "    ✓ SignTool: $($profile.signingToolPath)" -ForegroundColor Green
                } elseif ($profile.type -eq "azure") {
                    Write-Host "    ✓ Key Vault: $($profile.keyVaultUrl)" -ForegroundColor Green
                    Write-Host "    ✓ Certificate: $($profile.certificateName)" -ForegroundColor Green
                }
            } catch {
                Write-Host "    ✗ Profile file corrupted" -ForegroundColor Red
            }
        } else {
            Write-Host "    ✗ Profile file missing: $profilePath" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No configuration file found" -ForegroundColor Yellow
}
```

## Common Issues

### 1. "Module not found" Error

**Symptoms:**
- `Import-Module SignModule` fails
- Commands not available

**Solutions:**

```powershell
# Check if module is installed
Get-Module -ListAvailable SignModule

# Install from PowerShell Gallery
Install-Module -Name SignModule -Scope CurrentUser

# Or install manually
# 1. Download/clone repository
# 2. Copy to module path
$modulePath = ($env:PSModulePath -split ';')[0]
Copy-Item "C:\path\to\SignModule" "$modulePath\SignModule" -Recurse

# Import module
Import-Module SignModule -Force
```

### 2. "Profile not found" Error

**Symptoms:**
- `Export-SignedExecutable` fails with profile not found
- Profile appears to exist but cannot be loaded

**Solutions:**

```powershell
# List all profiles
$config = Get-Content "$env:PSModulePath\SignModule\config.json" | ConvertFrom-Json
$config.profiles.PSObject.Properties.Name

# Recreate missing profile
Add-SignProfile -ProfileName "MissingProfile"

# Fix corrupted configuration
Remove-Item "$env:PSModulePath\SignModule\config.json"
# Profiles will need to be recreated
```

### 3. "SignTool not found" Error

**Symptoms:**
- Signing fails with tool not found
- Local certificate profiles don't work

**Solutions:**

```powershell
# Find SignTool.exe
Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits" -Recurse -Name "signtool.exe" 2>$null

# Install Windows SDK
# Download from: https://developer.microsoft.com/windows/downloads/windows-sdk/

# Update profile with correct path
Update-SignProfile -ProfileName "YourProfile"
# Provide correct SignTool.exe path when prompted
```

### 4. Certificate Access Issues

**Symptoms:**
- "Certificate not found" errors
- "Access denied" when signing
- Invalid certificate password

**Solutions:**

```powershell
# Check certificate file exists and is accessible
Test-Path "C:\path\to\certificate.pfx"

# Verify certificate password
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import("C:\path\to\certificate.pfx", "password", "DefaultKeySet")

# Update certificate password
Update-SignProfile -ProfileName "YourProfile"

# Check file permissions
Get-Acl "C:\path\to\certificate.pfx" | Format-List
```

### 5. Azure Key Vault Connection Issues

**Symptoms:**
- Azure signing fails
- Authentication errors
- Network timeouts

**Solutions:**

```powershell
# Test Azure connectivity
Test-NetConnection login.microsoftonline.com -Port 443

# Verify service principal
# Use Azure CLI or PowerShell to test authentication
az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId

# Check Key Vault permissions
# Ensure service principal has "Sign" permission on certificate

# Update Azure credentials
Update-SignProfile -ProfileName "AzureProfile"
```

## Error Messages

### Configuration Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Profile 'X' already exists" | Duplicate profile name | Use different name or remove existing |
| "Invalid profile name" | Invalid characters in name | Use alphanumeric and basic symbols only |
| "Configuration directory not accessible" | Permission issues | Run as administrator or fix permissions |
| "Profile file corrupted" | Invalid JSON format | Remove and recreate profile |

### Signing Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "File not found" | Missing executable file | Verify file path and existence |
| "File is not an executable" | Wrong file extension | Only .exe files supported |
| "SignTool.exe not found" | Missing Windows SDK | Install Windows SDK |
| "Certificate not found" | Missing certificate file | Verify certificate path |
| "Invalid certificate password" | Wrong password | Update profile with correct password |
| "Timestamp server unavailable" | Network/server issues | Try different timestamp server |

### Azure-Specific Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Authentication failed" | Invalid credentials | Update service principal details |
| "Certificate not found in Key Vault" | Wrong certificate name | Verify certificate exists in Key Vault |
| "Access denied to Key Vault" | Insufficient permissions | Grant "Sign" permission to service principal |
| "Key Vault not found" | Wrong URL or deleted vault | Verify Key Vault URL |

## Configuration Problems

### Corrupted Configuration

If your configuration becomes corrupted:

```powershell
# Backup existing configuration
Copy-Item "$env:PSModulePath\SignModule" "$env:PSModulePath\SignModule.backup" -Recurse

# Reset configuration
Remove-Item "$env:PSModulePath\SignModule\config.json" -Force

# Recreate profiles
Add-SignProfile -ProfileName "Profile1"
Add-SignProfile -ProfileName "Profile2"
```

### Missing Configuration Directory

```powershell
# Manually create configuration directory
$configDir = "$env:PSModulePath\SignModule"
New-Item -ItemType Directory -Path $configDir -Force
New-Item -ItemType Directory -Path "$configDir\profiles" -Force

# Initialize configuration
Import-Module SignModule
Add-SignProfile -ProfileName "Test"
```

### Permission Issues

```powershell
# Fix configuration directory permissions
$configDir = "$env:PSModulePath\SignModule"
$acl = Get-Acl $configDir
$acl.SetAccessRuleProtection($true, $false)
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl $configDir $acl
```

## Certificate Issues

### Certificate Validation

```powershell
# Test certificate file
function Test-Certificate {
    param([string]$CertPath, [string]$Password)
    
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($CertPath, $Password, "DefaultKeySet")
        
        Write-Host "Certificate Details:" -ForegroundColor Green
        Write-Host "  Subject: $($cert.Subject)"
        Write-Host "  Issuer: $($cert.Issuer)"
        Write-Host "  Valid From: $($cert.NotBefore)"
        Write-Host "  Valid To: $($cert.NotAfter)"
        Write-Host "  Has Private Key: $($cert.HasPrivateKey)"
        
        if ($cert.NotAfter -lt (Get-Date)) {
            Write-Host "  ⚠ Certificate has expired!" -ForegroundColor Red
        }
        
        return $true
    }
    catch {
        Write-Host "Certificate validation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Usage
Test-Certificate -CertPath "C:\path\to\cert.pfx" -Password "yourpassword"
```

### Certificate Store Issues

```powershell
# Check certificate in Windows store
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*YourCompany*" }
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*YourCompany*" }

# Export certificate from store
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*YourCompany*" }
Export-PfxCertificate -Cert $cert -FilePath "C:\temp\exported.pfx" -Password (ConvertTo-SecureString "password" -AsPlainText -Force)
```

## Azure Key Vault Issues

### Service Principal Testing

```powershell
# Test service principal authentication
function Test-AzureAuth {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    try {
        $body = @{
            grant_type = "client_credentials"
            client_id = $ClientId
            client_secret = $ClientSecret
            resource = "https://vault.azure.net"
        }
        
        $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" -Method Post -Body $body
        Write-Host "✓ Authentication successful" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Usage
Test-AzureAuth -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-secret"
```

### Key Vault Connectivity

```powershell
# Test Key Vault connectivity
function Test-KeyVaultAccess {
    param([string]$KeyVaultUrl)
    
    try {
        $uri = "$KeyVaultUrl/certificates?api-version=7.0"
        $response = Invoke-WebRequest -Uri $uri -Method Get
        Write-Host "✓ Key Vault accessible" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Key Vault access failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Usage
Test-KeyVaultAccess -KeyVaultUrl "https://myvault.vault.azure.net"
```

## Performance Issues

### Slow Signing Operations

**Causes and Solutions:**

1. **Network latency** (Azure/timestamp servers)
   ```powershell
   # Test timestamp server response
   Measure-Command { Invoke-WebRequest "http://timestamp.digicert.com" }
   
   # Try different timestamp servers
   $servers = @(
       "http://timestamp.digicert.com",
       "http://timestamp.comodoca.com",
       "http://timestamp.verisign.com/scripts/timstamp.dll"
   )
   
   foreach ($server in $servers) {
       $time = Measure-Command { 
           try { Invoke-WebRequest $server -TimeoutSec 5 } catch {} 
       }
       Write-Host "$server : $($time.TotalMilliseconds)ms"
   }
   ```

2. **Large batch operations**
   ```powershell
   # Process files in smaller batches
   $files = Get-ChildItem "*.exe"
   $batchSize = 10
   
   for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
       $batch = $files[$i..($i + $batchSize - 1)]
       $batch | Export-SignedExecutable -ProfileName "Production"
       Write-Progress -Activity "Signing" -PercentComplete (($i / $files.Count) * 100)
   }
   ```

3. **Certificate access delays**
   ```powershell
   # Pre-load certificate to test access speed
   Measure-Command {
       $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
       $cert.Import("C:\path\to\cert.pfx", "password", "DefaultKeySet")
   }
   ```

## Debug Mode

### Enable Verbose Output

```powershell
# Enable verbose output for all SignModule operations
$VerbosePreference = "Continue"

# Run operations with verbose output
Export-SignedExecutable -ProfileName "Test" -Files "test.exe" -Verbose

# Reset verbose preference
$VerbosePreference = "SilentlyContinue"
```

### PowerShell Debugging

```powershell
# Enable PowerShell debugging
Set-PSDebug -Trace 1

# Run SignModule operations
Add-SignProfile -ProfileName "Debug"

# Disable debugging
Set-PSDebug -Off
```

## Getting Help

### Built-in Help

```powershell
# Get help for specific commands
Get-Help Add-SignProfile -Full
Get-Help Export-SignedExecutable -Examples
Get-Help Update-SignProfile -Parameter ProfileName

# List all SignModule commands
Get-Command -Module SignModule
```

### Log Files and Event Viewer

```powershell
# Check Windows Event Viewer
# Navigate to: Applications and Services Logs → Microsoft → Windows → CodeIntegrity

# PowerShell event logs
Get-WinEvent -LogName "Windows PowerShell" | Where-Object { $_.Message -like "*SignModule*" }

# Application event logs
Get-EventLog -LogName Application -Source "SignModule" -ErrorAction SilentlyContinue
```

### Collecting Diagnostic Information

```powershell
# Collect diagnostic information
$diagnostics = @{
    PowerShellVersion = $PSVersionTable.PSVersion
    ModuleVersion = (Get-Module SignModule).Version
    ConfigPath = "$env:PSModulePath\SignModule"
    Profiles = @()
}

# Add profile information (non-sensitive)
$configFile = "$env:PSModulePath\SignModule\config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    foreach ($profileName in $config.profiles.PSObject.Properties.Name) {
        $profilePath = $config.profiles.$profileName.path
        if (Test-Path $profilePath) {
            $profile = Get-Content $profilePath | ConvertFrom-Json
            $diagnostics.Profiles += @{
                Name = $profileName
                Type = $profile.type
                Exists = $true
            }
        }
    }
}

# Export diagnostics
$diagnostics | ConvertTo-Json -Depth 3 | Out-File "$env:TEMP\SignModule-Diagnostics.json"
Write-Host "Diagnostics saved to: $env:TEMP\SignModule-Diagnostics.json"
```

### Community Support

- **GitHub Issues**: [Report bugs and request features](https://github.com/GrafGenerator/pwsh-sign-module/issues)
- **GitHub Discussions**: [Ask questions and share ideas](https://github.com/GrafGenerator/pwsh-sign-module/discussions)
- **Documentation**: [Read the full documentation](https://github.com/GrafGenerator/pwsh-sign-module)

### Creating Bug Reports

When reporting issues, please include:

1. **Environment Information**:
   - PowerShell version (`$PSVersionTable`)
   - SignModule version
   - Windows version
   - Signing tool versions

2. **Steps to Reproduce**:
   - Exact commands used
   - Configuration details (non-sensitive)
   - Expected vs actual behavior

3. **Error Messages**:
   - Full error text
   - Stack traces if available
   - Event log entries

4. **Diagnostic Output**:
   - Use the diagnostic script above
   - Include verbose output if relevant

---

*This troubleshooting guide is regularly updated. For the latest version, visit the [GitHub repository](https://github.com/GrafGenerator/pwsh-sign-module).*
