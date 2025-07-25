function Convert-SecureStringToPlainText {
    param(
        [Parameter(Mandatory)]
        [System.Security.SecureString]$SecureString
    )

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($bstr) | Out-Null
    }
}
