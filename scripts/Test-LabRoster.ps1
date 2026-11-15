<#
.SYNOPSIS
  Reconcile the 28 archived CSV employees plus two separately documented users
  against a 30-account CORP lab roster.
.DESCRIPTION
  New post-lab read-only helper. Offline mode compares a two-column roster CSV
  (Username,Department). -Live queries the isolated CORP domain on DC01.
  No account, group, policy, or permission changes are made.
  Neither a passing offline test nor this script's presence proves a live run.
.EXAMPLE
  .\scripts\Test-LabRoster.ps1 -RosterPath .\tests\roster-export.csv
.EXAMPLE
  .\scripts\Test-LabRoster.ps1 -Live
#>
[CmdletBinding(DefaultParameterSetName = 'Offline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Offline')]
    [string]$RosterPath,

    [Parameter(Mandatory, ParameterSetName = 'Live')]
    [switch]$Live,

    [string]$HistoricalCsvPath = (Join-Path $PSScriptRoot 'historical/employees.csv')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $HistoricalCsvPath -PathType Leaf)) {
    throw "Archived CSV not found: $HistoricalCsvPath"
}
$archived = @(Import-Csv -LiteralPath $HistoricalCsvPath -ErrorAction Stop)
if ($archived.Count -ne 28) {
    throw "Expected 28 archived CSV records, found $($archived.Count)."
}
if ((@($archived[0].PSObject.Properties.Name) -join ',') -cne 'FirstName,LastName,Username,Department') {
    throw 'Archived CSV columns/order do not match FirstName,LastName,Username,Department.'
}

$expected = [System.Collections.Generic.Dictionary[string,string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
foreach ($employee in $archived) {
    $username = ([string]$employee.Username).Trim()
    $department = ([string]$employee.Department).Trim()
    if ($username -notmatch '^[a-z][a-z0-9._-]{1,19}$' -or
        $department -notin @('IT','HR','Finance','Operations')) {
        throw "Invalid archived username or department: $username"
    }
    if ($expected.ContainsKey($username)) { throw "Duplicate archived username: $username" }
    $expected.Add($username, $department)
}
foreach ($additional in @(
    @{ Username = 'amorgan'; Department = 'IT' },
    @{ Username = 'sjohnson'; Department = 'Finance' }
)) {
    if ($expected.ContainsKey($additional.Username)) {
        throw "Separately documented username is already in archived CSV: $($additional.Username)"
    }
    $expected.Add($additional.Username, $additional.Department)
}

if ($Live) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $domain = Get-ADDomain -ErrorAction Stop
    if ($domain.DNSRoot -ine 'corp.example.test') {
        throw "Safety stop: live domain is '$($domain.DNSRoot)', expected corp.example.test."
    }
    $ou = 'OU=Company,DC=corp,DC=example,DC=test'
    $users = @(Get-ADUser -Filter * -SearchBase $ou -SearchScope Subtree -ErrorAction Stop)
    $roster = @(
        foreach ($user in $users) {
            $match = [regex]::Match([string]$user.DistinguishedName,
                '(?i)(?:^|,)OU=(IT|HR|Finance|Operations)(?=,|$)')
            [pscustomobject]@{
                Username = [string]$user.SamAccountName
                Department = $(if ($match.Success) { $match.Groups[1].Value } else { 'UNMAPPED' })
            }
        }
    )
}
else {
    if (-not (Test-Path -LiteralPath $RosterPath -PathType Leaf)) {
        throw "Roster CSV not found: $RosterPath"
    }
    $roster = @(Import-Csv -LiteralPath $RosterPath -ErrorAction Stop)
    if ($roster.Count -eq 0) { throw 'Roster CSV is empty.' }
    if ((@($roster[0].PSObject.Properties.Name) -join ',') -cne 'Username,Department') {
        throw 'Roster CSV must have exactly Username,Department columns in that order.'
    }
}

$issues = [System.Collections.Generic.List[string]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
foreach ($user in $roster) {
    $username = ([string]$user.Username).Trim()
    $department = ([string]$user.Department).Trim()
    if ([string]::IsNullOrWhiteSpace($username)) {
        $issues.Add('Roster contains a blank username.')
        continue
    }
    if (-not $seen.Add($username)) {
        $issues.Add("Duplicate username in roster: $username")
        continue
    }
    if (-not $expected.ContainsKey($username)) {
        $issues.Add("Unexpected username in roster: $username")
    }
    elseif ($department -ine $expected[$username]) {
        $issues.Add(("Department mismatch for {0}: expected {1}, got {2}" -f
            $username, $expected[$username], $department))
    }
}
foreach ($username in $expected.Keys) {
    if (-not $seen.Contains($username)) {
        $issues.Add("Missing username from roster: $username")
    }
}
if ($roster.Count -ne 30) {
    $issues.Add("Roster has $($roster.Count) accounts; expected 30.")
}
$expectedCounts = @{ IT = 8; HR = 7; Finance = 8; Operations = 7 }
foreach ($department in @('IT','HR','Finance','Operations')) {
    $actualCount = @($roster | Where-Object { $_.Department -ieq $department }).Count
    if ($actualCount -ne $expectedCounts[$department]) {
        $issues.Add(("Department {0} has {1} accounts; expected {2}." -f
            $department, $actualCount, $expectedCounts[$department]))
    }
}

if ($issues.Count -gt 0) {
    foreach ($issue in $issues) { Write-Warning $issue }
    throw ("Roster reconciliation FAILED ({0} issue(s)): {1}" -f
        $issues.Count, ($issues -join '; '))
}
Write-Host 'PASS: 30 unique fictional users match the 28 archived CSV rows plus amorgan (IT) and sjohnson (Finance).' -ForegroundColor Green
Write-Host 'PASS: department counts are IT 8, HR 7, Finance 8, Operations 7.' -ForegroundColor Green
if (-not $Live) {
    Write-Host 'LIMIT: Offline CSV comparison only; no DC01 directory was queried.'
}
else {
    Write-Host 'LIMIT: AD roster verified at query time; this does not test logon or effective access.'
}
