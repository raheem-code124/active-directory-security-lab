<#
.SYNOPSIS
  Example rerunnable, department-aware AD provisioning for the isolated CORP lab.
.DESCRIPTION
  NEW reconstruction written AFTER the original hands-on lab. The historical
  The historical Create-Employees-v3.ps1 is archived separately, unchanged.
  Default behavior is READ-ONLY planning; -Apply authorizes AD modifications.
  New accounts are DISABLED without passwords. Set passwords and enable accounts
  separately under your lab's approved procedure. No credentials are stored.
.EXAMPLE
  .\Invoke-LabEmployeeProvisioning.ps1 -CsvPath ..\tests\sample-employees.csv
.EXAMPLE
  .\Invoke-LabEmployeeProvisioning.ps1 -CsvPath ..\tests\sample-employees.csv -Apply -WhatIf
.EXAMPLE
  .\Invoke-LabEmployeeProvisioning.ps1 -CsvPath ..\tests\sample-employees.csv -Apply
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$CompanyOu = 'OU=Company,DC=corp,DC=example,DC=test',
    [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot 'EmployeeCsv.Validation.psm1') -Force -ErrorAction Stop

$domain = Get-ADDomain -ErrorAction Stop
if ($domain.DNSRoot -ine 'corp.example.test') {
    throw "Safety stop: domain is '$($domain.DNSRoot)', expected corp.example.test."
}
$employees = @(Import-LabEmployees -Path $CsvPath)
$rootOu = Get-ADOrganizationalUnit -Identity $CompanyOu -ErrorAction Stop
if (-not $rootOu) { throw 'Company OU not found.' }

# Preflight: validate every OU, group, and account location BEFORE any changes.
$plan = @()
foreach ($employee in $employees) {
    $ouDn = "OU=$($employee.OuName),$CompanyOu"
    $null = Get-ADOrganizationalUnit -Identity $ouDn -ErrorAction Stop
    $null = Get-ADGroup -Identity $employee.Group -ErrorAction Stop
    $username = $employee.Username
    $existing = @(Get-ADUser -Filter "SamAccountName -eq '$username'" -Properties DistinguishedName -ErrorAction Stop)
    if ($existing.Count -gt 1) { throw "Ambiguous directory username: $username" }
    if ($existing.Count -gt 0 -and -not $existing[0].DistinguishedName.EndsWith(
        ",$ouDn", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Existing account $username is outside expected OU $ouDn. No changes made."
    }
    $member = $false
    if ($existing.Count -gt 0) {
        $groups = @(Get-ADPrincipalGroupMembership -Identity $existing[0] -ErrorAction Stop)
        $member = @($groups | Where-Object Name -eq $employee.Group).Count -gt 0
    }
    $action = if ($existing.Count -eq 0) { 'CREATE_DISABLED_AND_ADD_GROUP' }
              elseif (-not $member) { 'ADD_MISSING_GROUP' }
              else { 'ALREADY_CORRECT' }
    $plan += [pscustomobject]@{
        Username=$username; Department=$employee.Department
        Group=$employee.Group; DistinguishedOu=$ouDn
        Action=$action; FirstName=$employee.FirstName; LastName=$employee.LastName
    }
}
$plan | Select-Object Username,Department,Group,Action | Format-Table -AutoSize
if (-not $Apply) {
    Write-Host 'PLAN ONLY. No AD changes. Use -Apply after review.' -ForegroundColor Cyan
    return
}

foreach ($item in $plan) {
    if ($item.Action -eq 'ALREADY_CORRECT') { continue }
    $target = "$($item.Username) in $($item.DistinguishedOu)"
    if (-not $PSCmdlet.ShouldProcess($target, $item.Action)) { continue }
    if ($item.Action -eq 'CREATE_DISABLED_AND_ADD_GROUP') {
        $parameters = @{
            Name="$($item.FirstName) $($item.LastName)"
            GivenName=$item.FirstName
            Surname=$item.LastName
            SamAccountName=$item.Username
            UserPrincipalName="$($item.Username)@corp.example.test"
            Path=$item.DistinguishedOu
            Enabled=$false
            Description='Fictional CORP lab account; disabled pending password enrollment'
            ErrorAction='Stop'
        }
        $null = New-ADUser @parameters
    }
    # If membership addition fails, the disabled account remains and a rerun
    # will find it and finish the missing group assignment.
    Add-ADGroupMember -Identity $item.Group -Members $item.Username -ErrorAction Stop
    Write-Host "APPLIED $($item.Action): $($item.Username) -> $($item.Group)"
}
Write-Host 'Re-run in plan mode to verify all desired memberships and account locations.'
