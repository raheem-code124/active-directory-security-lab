<#
.SYNOPSIS
  Read-only inventory and validation of the fictional CORP lab on DC01.
.DESCRIPTION
  Written AFTER the hands-on lab for reproducibility. This script has not been
  claimed as the original deployment script or as executed in screenshot evidence.
  Performs no modifications to Active Directory, DHCP, DNS, SMB, or GPO settings.
.NOTES
  Expected environment: Windows Server 2025 DC01, corp.example.test.
  Run in an elevated PowerShell window with AD/DHCP/DNS Server cmdlets available.
#>

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

function Add-Check {
    param([string]$Area, [string]$Check, $Actual, $Expected)
    $actualText = [string]$Actual
    $expectedText = [string]$Expected
    $results.Add([pscustomobject]@{
        Area     = $Area
        Check    = $Check
        Actual   = $actualText
        Expected = $expectedText
        Pass     = ($actualText -eq $expectedText)
    })
}

Write-Host 'CORP lab read-only verification (new portfolio helper)' -ForegroundColor Cyan

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $domain = Get-ADDomain
    Add-Check Identity 'Domain DNS root' $domain.DNSRoot 'corp.example.test'
    Add-Check Identity 'NetBIOS name' $domain.NetBIOSName 'CORP'

    $ou = 'OU=Company,DC=corp,DC=example,DC=test'
    $count = @(Get-ADUser -Filter * -SearchBase $ou).Count
    Add-Check Identity 'Employees in Company OU' $count 30

    foreach ($item in @(
        @{Name='SG_IT_Users';Count=8},
        @{Name='SG_HR_Users';Count=7},
        @{Name='SG_Finance_Users';Count=8},
        @{Name='SG_Operations_Users';Count=7}
    )) {
        $memberCount = @(Get-ADGroupMember -Identity $item.Name).Count
        Add-Check Identity "Group $($item.Name)" $memberCount $item.Count
    }

    foreach ($testObject in @('lockout.test','audit.test')) {
        $present = @(Get-ADUser -Filter "SamAccountName -eq '$testObject'").Count
        Add-Check Cleanup "Absent user $testObject" $present 0
    }
    $testGroup = @(Get-ADGroup -Filter "SamAccountName -eq 'SG_Audit_Test'").Count
    Add-Check Cleanup 'Absent temporary group' $testGroup 0
    $testPso = @(Get-ADFineGrainedPasswordPolicy -Filter "Name -eq 'PSO-Lockout-Test'").Count
    Add-Check Cleanup 'Absent temporary PSO' $testPso 0
}
catch { $errors.Add("Active Directory: $($_.Exception.Message)"); Write-Warning "Active Directory checks incomplete: $($_.Exception.Message)" }

try {
    $scope = Get-DhcpServerv4Scope -ScopeId '192.168.50.0'
    Add-Check DHCP 'Scope state' $scope.State 'Active'
    Add-Check DHCP 'Start IP' $scope.StartRange.IPAddressToString '192.168.50.100'
    Add-Check DHCP 'End IP' $scope.EndRange.IPAddressToString '192.168.50.200'
    $option = Get-DhcpServerv4OptionValue -ScopeId '192.168.50.0'
    $dnsServer = ($option | Where-Object OptionId -eq 6).Value -join ','
    Add-Check DHCP 'Option 006 DNS server' $dnsServer '192.168.50.10'
}
catch { $errors.Add("DHCP: $($_.Exception.Message)"); Write-Warning "DHCP checks incomplete: $($_.Exception.Message)" }

try {
    $zone = Get-DnsServerZone -Name '50.168.192.in-addr.arpa'
    Add-Check DNS 'Reverse zone exists' ([bool]$zone) 'True'
    $ptr = Get-DnsServerResourceRecord -ZoneName '50.168.192.in-addr.arpa' -RRType PTR |
        Where-Object HostName -eq '10' |
        Select-Object -First 1
    if ($ptr) {
        Add-Check DNS 'PTR of 192.168.50.10' $ptr.RecordData.PtrDomainName.TrimEnd('.') 'DC01.corp.example.test'
    }
    else { Add-Check DNS 'PTR of 192.168.50.10' '<not found>' 'DC01.corp.example.test' }
}
catch { $errors.Add("DNS: $($_.Exception.Message)"); Write-Warning "DNS checks incomplete: $($_.Exception.Message)" }

try {
    foreach ($dept in @('Finance','HR','IT','Operations')) {
        $share = Get-SmbShare -Name $dept
        Add-Check SMB "Share $dept path" $share.Path "C:\CompanyShares\$dept"
    }
}
catch { $errors.Add("SMB: $($_.Exception.Message)"); Write-Warning "SMB checks incomplete: $($_.Exception.Message)" }

Write-Host ''
$results | Format-Table Area,Check,Actual,Expected,Pass -AutoSize
$failed = @($results | Where-Object { -not $_.Pass }).Count
Write-Host ("Checks: {0} completed, {1} mismatched, {2} sections errored." -f $results.Count,$failed,$errors.Count)
foreach ($errorMessage in $errors) { Write-Warning $errorMessage }
if ($results.Count -eq 0 -or $failed -gt 0 -or $errors.Count -gt 0) {
    throw "Lab verification INCOMPLETE/FAILED. Review mismatches and errors; do not report a PASS."
}
Write-Host 'Lab verification checks PASSED (limited to the checks listed above).' -ForegroundColor Green
Write-Host "Note: This does not confirm CLIENT01 GPOs, SMB effective user access, or resolve DNS query timeouts."
