# Run-Tests.ps1
# Script to run all Pester tests for the SignModule

param(
    [Parameter()]
    [switch]$SkipPrivateFunctions,

    [Parameter()]
    [switch]$SkipPublicFunctions,

    [Parameter()]
    [switch]$SkipScripts
)

# Install Pester if not already installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Output "Pester module not found. Installing..."
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

# Import Pester module
Import-Module Pester

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Define test paths
$testPaths = @()

if (-not $SkipPrivateFunctions) {
    $testPaths += Join-Path $scriptPath "Unit\Private"
}

if (-not $SkipPublicFunctions) {
    $testPaths += Join-Path $scriptPath "Unit\Public"
}

if (-not $SkipScripts) {
    $testPaths += Join-Path $scriptPath "Unit\Scripts"
}

# Configure Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testPaths
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.TestResult.OutputPath = "testResults.xml"
$pesterConfig.TestResult.Enabled = $True

# Run the tests
Invoke-Pester -Configuration $pesterConfig
