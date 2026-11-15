# SYNTHETIC OFFLINE TEST; does not connect to any Active Directory domain.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/EmployeeCsv.Validation.psm1') -Force
$valid = @(Import-LabEmployees -Path (Join-Path $PSScriptRoot 'sample-employees.csv'))
if ($valid.Count -ne 4) { throw "Expected four synthetic employees." }
$expected = @('SG_IT_Users','SG_HR_Users','SG_Finance_Users','SG_Operations_Users')
for ($i=0; $i -lt $valid.Count; $i++) {
    if ($valid[$i].Group -ne $expected[$i]) { throw "Invalid mapping at index $i" }
}
$rejected = $false
try {
    $null = @(Import-LabEmployees -Path (Join-Path $PSScriptRoot 'invalid-duplicate-employees.csv'))
}
catch {
    if ($_.Exception.Message -match 'Duplicate username') { $rejected=$true }
    else { throw }
}
if (-not $rejected) { throw 'Duplicate username was not rejected.' }
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('corp-csv-invalid-' + [guid]::NewGuid().ToString('N') + '.csv')
try {
    @(
        'FirstName,LastName,Username,Department,UnexpectedColumn'
        'Test,Employee,temployee,IT,ignored'
    ) | Set-Content -LiteralPath $scratch -Encoding utf8
    $rejectedExtra = $false
    try {
        $null = @(Import-LabEmployees -Path $scratch)
    }
    catch {
        if ($_.Exception.Message -match 'exactly FirstName,LastName,Username,Department') {
            $rejectedExtra = $true
        } else { throw }
    }
    if (-not $rejectedExtra) { throw 'Unexpected CSV column was not rejected.' }
    @(
        'FirstName,LastName,Username,Department'
        'Test,Employee,temployee,Unrecognized'
    ) | Set-Content -LiteralPath $scratch -Encoding utf8
    $rejectedDepartment = $false
    try {
        $null = @(Import-LabEmployees -Path $scratch)
    }
    catch {
        if ($_.Exception.Message -match 'Invalid department') {
            $rejectedDepartment = $true
        } else { throw }
    }
    if (-not $rejectedDepartment) { throw 'Invalid department was not rejected.' }
}
finally {
    Remove-Item -LiteralPath $scratch -Force -ErrorAction SilentlyContinue
}
Write-Host 'PASS: synthetic group mapping, duplicate detection, invalid department and unexpected column rejection.' -ForegroundColor Green
