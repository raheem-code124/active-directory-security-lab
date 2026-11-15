<#
.SYNOPSIS
  Read domain controller Security event IDs relevant to the CORP lab.
.DESCRIPTION
  New read-only analysis helper. It does not modify auditing or AD.
  Use -OutputPath only for a LOCAL CSV that you will inspect before sharing.
  Requires permission to read the Windows Security log.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 168)]
    [int]$HoursBack = 24,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$ids = @(4720,4726,4728,4730,4771,4740,4767)
$start = (Get-Date).AddHours(-$HoursBack)

Write-Host ("Reading Security event IDs {0} since {1}" -f ($ids -join ','),$start) -ForegroundColor Cyan

# A quiet lab log is a valid result; permissions and other errors still fail.
try {
    $events = @(Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        Id        = $ids
        StartTime = $start
    } -ErrorAction Stop)
}
catch {
    if ($_.FullyQualifiedErrorId -match 'NoMatchingEventsFound' -or
        $_.Exception.Message -match 'No events were found') {
        $events = @()
    }
    else { throw }
}
if ($events.Count -eq 0) {
    Write-Host 'No matching Security events in this time window. No CSV created.'
    return
}

$rows = @($events | Select-Object TimeCreated,Id,ProviderName,RecordId,
    @{Name='Summary';Expression={
        $line = ($_.Message -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -First 1)
        [string]$line
    }})

$rows | Format-Table -AutoSize
Write-Host ("Matched events: {0}. Review full events in Event Viewer for target, subject and source data." -f $rows.Count)

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        throw "Output directory does not exist: $parent"
    }
    $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Local CSV written: $OutputPath"
    Write-Warning "Inspect exported metadata before sharing; do not commit raw Security event logs."
}
