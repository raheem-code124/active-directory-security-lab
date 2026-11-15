# Fully synthetic offline reconciliation tests; no AD module or server is used.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root 'scripts/Test-LabRoster.ps1'
$historicalPath = Join-Path $root 'scripts/historical/employees.csv'
$tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) ('corp-roster-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempFolder -ItemType Directory -ErrorAction Stop | Out-Null

function Test-Case {
    param([string]$Name, [object[]]$Rows, [string]$ExpectedError = '')
    $path = Join-Path $tempFolder "$Name.csv"
    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -ErrorAction Stop
    $caught = ''
    try {
        & $scriptPath -RosterPath $path -HistoricalCsvPath $historicalPath | Out-Null
    }
    catch {
        $caught = $_.Exception.Message
    }
    if ([string]::IsNullOrEmpty($ExpectedError)) {
        if ($caught) { throw "$Name should pass, but failed: $caught" }
    }
    elseif (-not $caught -or $caught -notlike "*$ExpectedError*") {
        throw "$Name should fail with '$ExpectedError'; actual: $caught"
    }
    Write-Host "PASS: synthetic $Name"
}
try {
    $archived = @(Import-Csv -LiteralPath $historicalPath)
    $valid = @($archived | ForEach-Object {
        [pscustomobject]@{ Username = $_.Username; Department = $_.Department }
    }) + @(
        [pscustomobject]@{ Username = 'amorgan'; Department = 'IT' },
        [pscustomobject]@{ Username = 'sjohnson'; Department = 'Finance' }
    )
    Test-Case -Name 'valid-30' -Rows $valid
    $missing = @($valid | Where-Object { $_.Username -ne 'sjohnson' })
    Test-Case -Name 'missing-user' -Rows $missing -ExpectedError 'Missing username'
    $duplicate = @($valid | Where-Object { $_.Username -ne 'sjohnson' }) + @($valid[0])
    Test-Case -Name 'duplicate-user' -Rows $duplicate -ExpectedError 'Duplicate username'
    $wrongDepartment = @($valid | ForEach-Object {
        if ($_.Username -eq 'amorgan') {
            [pscustomobject]@{ Username = $_.Username; Department = 'HR' }
        } else { $_ }
    })
    Test-Case -Name 'incorrect-department' -Rows $wrongDepartment -ExpectedError 'Department mismatch'
    $unexpected = @($valid | ForEach-Object {
        if ($_.Username -eq 'amorgan') {
            [pscustomobject]@{ Username = 'unexpected1'; Department = 'IT' }
        } else { $_ }
    })
    Test-Case -Name 'unexpected-user' -Rows $unexpected -ExpectedError 'Unexpected username'
    $wrongColumns = @($valid | ForEach-Object {
        [pscustomobject]@{ Account = $_.Username; Division = $_.Department }
    })
    Test-Case -Name 'wrong-csv-columns' -Rows $wrongColumns -ExpectedError 'exactly Username,Department'
}
finally {
    Remove-Item -LiteralPath $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'PASS: all six synthetic roster reconciliation cases.' -ForegroundColor Green
