# Offline historical-data integrity check. No AD connection or directory writes.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$csv = Join-Path $root 'scripts/historical/employees.csv'
$source = Join-Path $root 'scripts/historical/Create-Employees-v3.ps1'

if ((Get-Item -LiteralPath $csv).Length -ne 778) { throw 'Archived CSV does not match the documented 778-byte file size.' }
if ((Get-Item -LiteralPath $source).Length -ne 2599) { throw 'Archived script does not match the documented 2599-byte file size.' }

# Hash values recorded from the original DC01 screenshot 0097.
$expectedScriptSha = '645e351d5ace73f0ffd6ec938777f15be75d8ccdd6e757df80c70d1d1e8c2726'
$expectedCsvSha = '88e3c2c2ddf135bf67d38eaec27b7048d5975e68d3d191c911f1621e39799fad'
$actualScriptSha = (Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash
$actualCsvSha = (Get-FileHash -LiteralPath $csv -Algorithm SHA256 -ErrorAction Stop).Hash
if ($actualScriptSha -ine $expectedScriptSha) { throw 'Archived script SHA-256 differs from DC01 screenshot 0097.' }
if ($actualCsvSha -ine $expectedCsvSha) { throw 'Archived CSV SHA-256 differs from DC01 screenshot 0097.' }
$rows = @(Import-Csv -LiteralPath $csv)
if ($rows.Count -ne 28) { throw "Expected 28 archived records; got $($rows.Count)" }
$expectedColumns = @('FirstName','LastName','Username','Department')
$actualColumns = @($rows[0].PSObject.Properties.Name)
if (($actualColumns -join ',') -cne ($expectedColumns -join ',')) { throw 'Archived CSV column names/order changed.' }
$expectedDepartments = @('IT','HR','Finance','Operations')
foreach ($dept in $expectedDepartments) {
    $count = @($rows | Where-Object Department -eq $dept).Count
    if ($count -ne 7) { throw "Expected 7 archived employees in $dept; got $count" }
}
$names = @($rows | ForEach-Object { $_.Username.ToLowerInvariant() })
if (@($names | Select-Object -Unique).Count -ne 28) { throw 'Duplicate archived usernames.' }
if ('amorgan' -in $names -or 'sjohnson' -in $names) {
    throw 'Archived CSV unexpectedly contains an account documented as created separately.'
}
foreach ($row in $rows) {
    if ($row.Username -cnotmatch '^[a-z][a-z0-9]{1,19}$') { throw "Invalid archived username: $($row.Username)" }
}
Write-Host 'PASS: Historical CSV has 28 unique accounts, seven in each department, and excludes separately documented amorgan/sjohnson; archived file sizes match.' -ForegroundColor Green
Write-Host 'PASS: Archived script and CSV SHA-256 hashes match the values recorded on DC01 in screenshot 0097.' -ForegroundColor Green
Write-Host 'LIMIT: Hash identity at capture time is not evidence of original authorship or a particular execution history.'
