# OFFLINE SYNTHETIC TEST ONLY. No domain, Security log or production system is accessed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root 'scripts/Analyze-AuthenticationEvents.ps1'
$fixture = Join-Path $PSScriptRoot 'auth-events-synthetic.csv'
$findings = @(& $script -InputCsv $fixture -Threshold 3 -WindowMinutes 10)
if ($findings.Count -ne 1) { throw "Expected 1 finding; got $($findings.Count)" }
$f = $findings[0]
if ($f.User -ne 'sample.user' -or $f.SourceIp -ne '192.0.2.44' -or
    $f.BadPasswordFailures -ne 3 -or -not $f.LockoutEventObserved -or
    $f.LockoutCallerComputer -ne 'SAMPLE-CLIENT') {
    throw "Unexpected correlation: $($f | Out-String)"
}
Write-Host 'PASS: 3 synthetic 4771 failures correlate with synthetic 4740 lockout.' -ForegroundColor Green
