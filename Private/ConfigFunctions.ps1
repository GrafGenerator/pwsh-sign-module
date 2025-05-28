using namespace System.Security
using namespace System.IO

# Helper functions for configuration management
function Initialize-ModuleConfig {
    if (-not (Test-Path $script:CONFIG_FILE)) {
        @{ profiles = @{} } | ConvertTo-Json | Set-Content $script:CONFIG_FILE
    }
    if (-not (Test-Path $script:PROFILES_DIR)) {
        New-Item -ItemType Directory -Path $script:PROFILES_DIR | Out-Null
    }
}

function Get-Config {
    if (Test-Path $script:CONFIG_FILE) {
        Get-Content $script:CONFIG_FILE | ConvertFrom-Json -AsHashtable
    }
    else {
        @{ profiles = @{} }
    }
}

function Save-Config {
    param($Config)
    $Config | ConvertTo-Json | Set-Content $script:CONFIG_FILE
}

function Test-ProfileName {
    param([string]$ProfileName)
    if ($ProfileName -notmatch '^[a-zA-Z0-9_\-]+$') {
        throw "Profile name '$ProfileName' is invalid. Must contain only alphabetic, numeric, underscore and hyphen characters"
    }
}
