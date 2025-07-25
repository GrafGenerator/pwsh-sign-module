# Contributing to SignModule

Thank you for your interest in contributing to SignModule! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## 🤝 Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code:

- Produce quality code
- Think of consequences of your changes
- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain professionalism in all interactions

## 🚀 Getting Started

### Prerequisites

- **PowerShell 5.1** or **PowerShell Core 6+**
- **Git** for version control
- **Windows SDK** (for SignTool.exe) if testing signing functionality
- **Pester** testing framework
- **PSScriptAnalyzer** for code quality

### Development Environment

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```powershell
   git clone https://github.com/GrafGenerator/pwsh-sign-module.git
   cd pwsh-sign-module
   ```
3. **Add upstream remote**:
   ```powershell
   git remote add upstream https://github.com/GrafGenerator/pwsh-sign-module.git
   ```

## 🛠️ Development Setup

### Install Development Dependencies

```powershell
# Install required modules
Install-Module -Name Pester, PSScriptAnalyzer -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable Pester, PSScriptAnalyzer
```

### Project Structure

```
pwsh-sign-module/
├── Public/                 # Exported functions
├── Private/               # Internal functions
├── Scripts/               # Signing scripts
├── Tests/                 # Test files
│   ├── Unit/             # Unit tests
│   ├── TestHelpers/      # Test utilities
│   └── Run-Tests.ps1     # Test runner
├── .github/              # GitHub workflows
├── SignModule.psd1       # Module manifest
├── SignModule.psm1       # Module loader
└── README.md             # Documentation
```

### Import Module for Development

```powershell
# Import module from source
Import-Module .\SignModule.psd1 -Force

# Verify functions are available
Get-Command -Module SignModule
```

## 🔄 Making Changes

### Branching Strategy

1. **Create a feature branch** from `master`:
   ```powershell
   git checkout master
   git pull upstream master
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the guidelines below

3. **Commit your changes** with clear messages:
   ```powershell
   git add .
   git commit -m "Add: New feature description"
   ```

### Commit Message Format

Use clear, descriptive commit messages:

- `Add: New feature or functionality`
- `Fix: Bug fix or correction`
- `Update: Modification to existing feature`
- `Remove: Deletion of code or feature`
- `Docs: Documentation changes`
- `Test: Test-related changes`

Or:

- `Added new feature (brief description, 3-10 words)`
- `Fixed bug (brief description, 3-10 words)`
- `Updated documentation (brief description, 3-10 words)`
- `Removed unused code (brief description, 3-10 words)`
- `Refactored code (brief description, 3-10 words)`

### Types of Contributions

#### 🐛 Bug Fixes
- Include steps to reproduce the issue
- Add or update tests to cover the fix
- Update documentation if behavior changes

#### ✨ New Features
- Discuss major features in an issue first
- Include comprehensive tests
- Update documentation and examples
- Consider backward compatibility

#### 📚 Documentation
- Fix typos and improve clarity
- Add examples and use cases
- Update API documentation
- Improve code comments

#### 🧪 Tests
- Add missing test coverage
- Improve test reliability
- Add integration tests
- Performance testing

## 🧪 Testing

### Running Tests

```powershell
# Run all tests
.\Tests\Run-Tests.ps1

# Run specific test categories
.\Tests\Run-Tests.ps1 -SkipPrivateFunctions
.\Tests\Run-Tests.ps1 -SkipPublicFunctions
.\Tests\Run-Tests.ps1 -SkipScripts

# Run with verbose output
.\Tests\Run-Tests.ps1 -Verbose
```

### Writing Tests

#### Test Structure
```powershell
Describe "Function-Name" {
    BeforeAll {
        # Setup code
    }
    
    Context "When condition" {
        It "Should do something" {
            # Test code
            $result = Function-Name -Parameter "value"
            $result | Should -Be "expected"
        }
    }
    
    AfterAll {
        # Cleanup code
    }
}
```

#### Test Guidelines
- **One assertion per test** when possible
- **Use descriptive test names** that explain the scenario
- **Include edge cases** and error conditions
- **Mock external dependencies** (file system, network, etc.)
- **Clean up after tests** to avoid side effects

#### Mock Examples
```powershell
# Mock file system operations
Mock Test-Path { return $true }
Mock Get-Content { return '{"type": "local"}' | ConvertFrom-Json }

# Mock external commands
Mock Start-Process { return @{ ExitCode = 0 } }

# Verify mocks were called
Should -Invoke Test-Path -Exactly 1
```

### Test Coverage

Aim for high test coverage:
- **Public functions**: 100% coverage required
- **Private functions**: 90%+ coverage recommended
- **Error paths**: Include negative test cases
- **Integration**: Test function interactions

## 📝 Code Style

### PowerShell Style Guidelines

#### Function Structure
```powershell
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequiredParam,
        
        [Parameter()]
        [switch]$OptionalSwitch
    )
    
    begin {
        # Initialization code
    }
    
    process {
        # Main logic
        try {
            # Implementation
        }
        catch {
            Write-Error "Error message: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        # Cleanup code
    }
}
```

#### Naming Conventions
- **Functions**: Use approved PowerShell verbs (`Get-Verb`)
- **Variables**: Use camelCase (`$myVariable`)
- **Parameters**: Use PascalCase (`$MyParameter`)
- **Constants**: Use UPPER_CASE (`$CONSTANT_VALUE`)

#### Code Formatting
- **Indentation**: 4 spaces (no tabs)
- **Line length**: Max 120 characters
- **Braces**: Opening brace on same line
- **Quotes**: Use single quotes unless interpolation needed

#### Error Handling
```powershell
# Use try/catch for expected errors
try {
    $result = Risky-Operation
}
catch [SpecificException] {
    Write-Warning "Specific error occurred"
    return $false
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    throw
}

# Use Write-Error for user errors
if (-not $ValidInput) {
    Write-Error "Invalid input provided"
    return
}
```

### Code Quality

#### PSScriptAnalyzer
All code must pass PSScriptAnalyzer checks:

```powershell
# Run analyzer
Invoke-ScriptAnalyzer -Path . -Recurse

# Fix common issues automatically
Invoke-ScriptAnalyzer -Path . -Fix
```

#### Common Rules
- No unused variables
- Proper parameter validation
- Consistent formatting
- No hardcoded paths
- Proper error handling

## 📤 Submitting Changes

### Pull Request Process

1. **Update your branch** with latest upstream:
   ```powershell
   git checkout master
   git pull upstream master
   git checkout feature/your-feature
   git rebase master
   ```

2. **Run all tests** and ensure they pass:
   ```powershell
   .\Tests\Run-Tests.ps1
   Invoke-ScriptAnalyzer -Path . -Recurse
   ```

3. **Push your changes**:
   ```powershell
   git push origin feature/your-feature
   ```

4. **Create a Pull Request** on GitHub

### Pull Request Guidelines

#### Title and Description
- **Clear title** describing the change
- **Detailed description** of what and why
- **Link to related issues** if applicable
- **Breaking changes** clearly marked

#### Checklist
- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
- [ ] Commit messages are clear
- [ ] Branch is up to date with master

#### Review Process
- Maintainers will review your PR
- Address feedback promptly
- Keep discussions constructive
- Be patient during the review process

## 🚀 Release Process

### Versioning

SignModule follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. Update version in `SignModule.psd1`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Create release tag
5. Publish to PowerShell Gallery

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Request Comments**: Code-specific discussions

### Questions?

If you have questions about contributing:

1. Check existing issues and documentation
2. Search previous discussions
3. Create a new issue with the `question` label
4. Be specific about what you're trying to achieve

## 🙏 Recognition

Contributors will be recognized in:
- `README.md` acknowledgments
- Release notes
- GitHub contributors page

Thank you for contributing to SignModule! 🎉

---

*This contributing guide is a living document and may be updated as the project evolves.*
