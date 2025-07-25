# TestSetup.ps1
# Common test setup functions and variables for Pester tests

# Module path
$script:ModuleRoot = (Get-Item (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))).FullName
$script:ModuleName = "SignModule"
$script:ScriptsPath = Join-Path -Path $ModuleRoot -ChildPath "Scripts"
$script:ModulePath = Join-Path -Path $ModuleRoot -ChildPath "$ModuleName.psm1"
$script:TestsPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..")).Path
$script:TestDataPath = Join-Path -Path $TestsPath -ChildPath "TestData"
$script:TempPath = Join-Path -Path $TestDataPath -ChildPath "temp"
$script:TestHelpersPath = Join-Path -Path $TestsPath -ChildPath "TestHelpers"

# Test profile paths
$script:TestConfigPath = Join-Path -Path $TestDataPath -ChildPath "config.json"
$script:TestProfilesDir = Join-Path -Path $TestDataPath -ChildPath "profiles"
$script:TestFilesDir = Join-Path -Path $TestDataPath -ChildPath "files"

# Test helper scripts paths
$script:TestSignToolPath = Join-Path $script:TestHelpersPath "SignToolHelper.ps1"

# Function to set up the test environment
function Initialize-TestEnvironment {
    # Create test directories if they don't exist
    if (-not (Test-Path $script:TestDataPath)) {
        New-Item -Path $script:TestDataPath -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $script:TempPath)) {
        New-Item -Path $script:TempPath -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $script:TestProfilesDir)) {
        New-Item -Path $script:TestProfilesDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $script:TestFilesDir)) {
        New-Item -Path $script:TestFilesDir -ItemType Directory -Force | Out-Null
    }

    # Create an empty test config file
    @{ profiles = @{} } | ConvertTo-Json | Set-Content -Path $script:TestConfigPath
}

# Function to clean up the test environment
function Remove-TestEnvironment {
    if (Test-Path $script:TestDataPath) {
        Remove-Item -Path $script:TestDataPath -Recurse -Force
    }
}

class TestSessionHelper {
    [guid] $SessionId
    [string] $FilePath

    TestSessionHelper([string] $testFilesPath, [string] $filePrefix) {
        $this.SessionId = [guid]::NewGuid();
        $this.FilePath = Join-Path $testFilesPath "$filePrefix$($this.SessionId).txt"
    }

    [string[]] GetCapturedLines() {
        $lines = @()
        foreach($line in [System.IO.File]::ReadLines($this.FilePath)) {
            $lines += $line
        }

        return $lines
    }
}
