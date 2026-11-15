<#
.SYNOPSIS
  Detect repeated failed Kerberos preauthentication and correlate nearby lockout events.
.DESCRIPTION
  NEW portfolio analysis helper written after the November 2026 lab.
  Reads Event 4771 (failure code 0x18) and Event 4740 from a domain controller,
  or a SYNTHETIC CSV fixture with identical logical field names.
  It DOES NOT claim historical deployment, production alerting, or causality.
  No Active Directory changes are made.
.EXAMPLE
  .\Analyze-AuthenticationEvents.ps1 -InputCsv ..\tests\auth-events-synthetic.csv
.EXAMPLE
  .\Analyze-AuthenticationEvents.ps1 -HoursBack 4 -Threshold 3 -WindowMinutes 10
#>
[CmdletBinding()]
param(
    [ValidateRange(1,168)][int]$HoursBack = 24,
    [ValidateRange(2,100)][int]$Threshold = 3,
    [ValidateRange(1,120)][int]$WindowMinutes = 10,
    [string]$InputCsv
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-EventDataValue {
    param([xml]$Xml, [string]$Field)
    foreach ($node in @($Xml.Event.EventData.Data)) {
        if ($node.GetAttribute('Name') -eq $Field) { return [string]$node.InnerText }
    }
    return ''
}
$records = @()
if ($InputCsv) {
    if (-not (Test-Path -LiteralPath $InputCsv -PathType Leaf)) {
        throw "Fixture not found: $InputCsv"
    }
    $rows = @(Import-Csv -LiteralPath $InputCsv)
    foreach ($row in $rows) {
        foreach ($required in @('TimeCreated','Id','User','SourceIp','Status','CallerComputer')) {
            if ($required -notin $row.PSObject.Properties.Name) {
                throw "CSV missing required column: $required"
            }
        }
        $records += [pscustomobject]@{
            TimeCreated = [datetime]::Parse($row.TimeCreated)
            Id = [int]$row.Id
            User = [string]$row.User
            SourceIp = [string]$row.SourceIp
            Status = [string]$row.Status
            CallerComputer = [string]$row.CallerComputer
        }
    }
}
else {
    try {
        $events = @(Get-WinEvent -FilterHashtable @{
            LogName='Security'
            Id=@(4771,4740)
            StartTime=(Get-Date).AddHours(-$HoursBack)
        } -ErrorAction Stop)
    }
    catch {
        if ($_.FullyQualifiedErrorId -match 'NoMatchingEventsFound' -or
            $_.Exception.Message -match 'No events were found') {
            $events = @()
        }
        else { throw }
    }
    foreach ($event in $events) {
        [xml]$xml = $event.ToXml()
        $records += [pscustomobject]@{
            TimeCreated = [datetime]$event.TimeCreated
            Id = [int]$event.Id
            User = (Get-EventDataValue -Xml $xml -Field 'TargetUserName')
            SourceIp = (Get-EventDataValue -Xml $xml -Field 'IpAddress')
            Status = (Get-EventDataValue -Xml $xml -Field 'Status')
            CallerComputer = (Get-EventDataValue -Xml $xml -Field 'CallerComputerName')
        }
    }
}

$failures = @($records | Where-Object {
    $_.Id -eq 4771 -and $_.Status -eq '0x18' -and
    -not [string]::IsNullOrWhiteSpace($_.User) -and
    -not [string]::IsNullOrWhiteSpace($_.SourceIp)
})
$lockouts = @($records | Where-Object { $_.Id -eq 4740 })
$groups = @($failures | Group-Object -Property {
    ($_.User.ToLowerInvariant() + '|' + ($_.SourceIp -replace '^::ffff:','').ToLowerInvariant())
})
foreach ($group in $groups) {
    $ordered = @($group.Group | Sort-Object TimeCreated)
    for ($i = 0; $i -lt $ordered.Count; $i++) {
        $last = $ordered[$i]
        $windowStart = $last.TimeCreated.AddMinutes(-$WindowMinutes)
        $inWindow = @($ordered | Where-Object {
            $_.TimeCreated -ge $windowStart -and $_.TimeCreated -le $last.TimeCreated
        })
        if ($inWindow.Count -lt $Threshold) { continue }
        $first = $inWindow[0]
        $matches = @($lockouts | Where-Object {
            $_.User -ieq $last.User -and
            $_.TimeCreated -ge $first.TimeCreated -and
            $_.TimeCreated -le $last.TimeCreated.AddMinutes(2)
        } | Sort-Object TimeCreated)
        $caller = if ($matches.Count -gt 0) { $matches[0].CallerComputer } else { '' }
        [pscustomobject]@{
            User = $last.User
            SourceIp = ($last.SourceIp -replace '^::ffff:', '')
            WindowStart = $first.TimeCreated
            WindowEnd = $last.TimeCreated
            BadPasswordFailures = $inWindow.Count
            LockoutEventObserved = ($matches.Count -gt 0)
            LockoutCallerComputer = $caller
            Finding = 'Review repeated bad-password attempts; correlation is not proof of compromise'
        }
        break
    }
}
