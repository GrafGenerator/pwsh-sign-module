using namespace System.Security
using namespace System.IO

# Module variables
$script:CONFIG_FILE = Join-Path $PSScriptRoot "config.json"
$script:PROFILES_DIR = Join-Path $PSScriptRoot "profiles"

# Import private functions
$privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Private") -Filter "*.ps1"
foreach ($file in $privateFiles) {
    . $file.FullName
}

# Import public functions
$publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Public") -Filter "*.ps1"
foreach ($file in $publicFiles) {
    . $file.FullName
}

# Export functions to make them available to module users
Export-ModuleMember -Function Add-SignProfile, Update-SignProfile, Remove-SignProfile, Clear-SignProfiles, Export-SignedExecutable
