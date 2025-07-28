# Changelog

All notable changes to the SignModule project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

## [1.0.1] - 2025-07-28

### Fixed
- License URL in the package description


## [1.0.0] - 2025-07-25

### Added
- Initial release of SignModule
- Core signing functionality with local certificates
- Azure Key Vault integration for cloud-based signing
- Profile management system (Add, Update, Remove, Clear)
- Secure storage of sensitive information using SecureString
- Comprehensive test suite with Pester
- Support for batch signing operations
- Pipeline support for signing multiple files
- Configuration management with JSON profiles
- Input validation and error handling
- Comprehensive documentation with detailed README
- Contributing guidelines (CONTRIBUTING.md)
- GitHub Actions CI/CD pipeline
- Enhanced help documentation for all public functions
- Code quality improvements with PSScriptAnalyzer integration
- Test result generation in NUnit XML format
- Detailed troubleshooting guide
- Usage examples and best practices

### Security
- Encrypted storage of passwords and secrets
- Secure profile configuration management
- Protected configuration directory access

## [0.9.0] - 2024-01-XX (Pre-release)

### Added
- Basic signing functionality
- Profile system foundation
- Initial test framework
- Core module structure

### Changed
- Refined API design
- Improved error handling
- Enhanced security model

## [0.1.0] - 2024-01-XX (Alpha)

### Added
- Initial project structure
- Basic PowerShell module framework
- Proof of concept signing functionality

---

## Release Notes

### Version 1.0.0 Features

**SignModule 1.0.0** is the first stable release of this PowerShell code signing module. Key features include:

#### 🔐 **Dual Signing Support**
- **Local Certificate Signing**: Use certificates stored locally (.pfx, .p12 files)
- **Azure Key Vault Integration**: Secure cloud-based signing with Azure Key Vault certificates

#### 📋 **Profile Management**
- Create and manage multiple signing profiles
- Secure storage of sensitive information
- Easy switching between different signing configurations
- Import/export profile configurations

#### ⚡ **Batch Operations**
- Sign multiple files simultaneously
- PowerShell pipeline support
- Recursive directory processing
- Flexible file filtering

#### 🛡️ **Security First**
- PowerShell SecureString encryption for passwords
- Protected configuration storage
- No plain-text secrets in configuration files
- Secure profile validation

#### 🧪 **Quality Assurance**
- Comprehensive test suite with Pester
- Continuous integration with GitHub Actions
- Code quality validation with PSScriptAnalyzer
- Automated testing on every commit

#### 📚 **Documentation**
- Detailed README with examples
- Comprehensive help for all functions
- Contributing guidelines for developers
- Troubleshooting guides and best practices

### Upgrade Guide

#### From Pre-release Versions
If upgrading from a pre-release version:

1. **Backup existing profiles**:
   ```powershell
   Copy-Item "$env:PSModulePath\SignModule" "$env:PSModulePath\SignModule.backup" -Recurse
   ```

2. **Uninstall old version**:
   ```powershell
   Remove-Module SignModule -Force
   ```

3. **Install new version**:
   ```powershell
   Install-Module SignModule -Force
   ```

4. **Verify installation**:
   ```powershell
   Get-Command -Module SignModule
   ```

#### Configuration Migration
Existing profiles from version 0.9.x are compatible with 1.0.0. No migration is required.

### Known Issues

#### Version 1.0.0
- None currently known

#### Workarounds
If you encounter issues:

1. **Profile corruption**: Remove and recreate the affected profile
2. **Permission errors**: Run PowerShell as Administrator for initial setup
3. **Certificate access**: Ensure certificate files have proper permissions

### Breaking Changes

#### From 0.9.x to 1.0.0
- None. Version 1.0.0 is fully backward compatible with 0.9.x profiles and configurations.

### Deprecations

#### Version 1.0.0
- No deprecations in this release

### Future Roadmap

#### Planned for 1.1.0
- Cross-platform support (Linux/macOS)
- Additional file type support (.dll, .msi)
- Enhanced logging and reporting
- PowerShell Gallery publishing automation

#### Planned for 1.2.0
- Hardware Security Module (HSM) support
- Advanced certificate management
- Signing verification utilities
- Performance optimizations

#### Planned for 2.0.0
- Major API enhancements
- Plugin architecture
- Advanced configuration management
- Enterprise features

---

## Contributing to Changelog

When contributing to this project, please update this changelog following these guidelines:

### Format
- Use [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format
- Group changes by type: Added, Changed, Deprecated, Removed, Fixed, Security
- Include version numbers and dates
- Link to relevant issues or pull requests

### Example Entry
```markdown
## [1.1.0] - 2024-02-15

### Added
- New feature description (#123)
- Another feature (#124)

### Fixed
- Bug fix description (#125)
```

### Types of Changes
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** in case of vulnerabilities

---

*For more information about releases, visit the [GitHub Releases](https://github.com/GrafGenerator/pwsh-sign-module/releases) page.*
