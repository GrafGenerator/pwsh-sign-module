$exitCodeIndex = $args.IndexOf("--exitCode")

if ($exitCodeIndex -gt -1) {
    $exitCode = $args[$exitCodeIndex + 1]
    exit $exitCode
}

$testOutFileIndex = $args.IndexOf("--testOutFile")
if ($testOutFileIndex -eq -1) {
    $argsText = $args[0] -join "|"
    throw "Test output file not specified. Passed arguments: $argsText"
}

$testOutFile = $args[$testOutFileIndex + 1]

$fullArgs = @($PSCommandPath) + $args

$fullArgs -join "`n" | Set-Content $testOutFile

exit 0