# Operations and troubleshooting runbook

[← Documentation hub](README.md) · [Config reference](configuration-reference.md) · [Evidence index](evidence-index.md)

This runbook collects **read-only** commands to validate the CORP lab, together with a decision process for common problems. Run Active Directory, DHCP, DNS Server, and server-side SMB commands in an **elevated PowerShell session on DC01**. Run workstation-specific commands on CLIENT01. The commands are references; the provided script is newly written and wasn't automatically executed as part of the historical screenshots.

## 1. Identity and DC health

```powershell
hostname
Get-ADDomain | Select-Object DNSRoot,NetBIOSName
Get-Service NTDS,DNS
Get-ADDomainController -Identity DC01
(Get-ADUser -Filter * -SearchBase "OU=Company,DC=corp,DC=example,DC=test").Count
```

**Expected:** DC01, `corp.example.test`, `CORP`, both NTDS/DNS running, 30 fictional employee objects.

**If wrong:** Check DNS/IP first; then AD DS state, service logs, and directory scope. Avoid recreating accounts simply because a list is shorter; check OU search scope.

## 2. Department group membership

```powershell
"SG_IT_Users","SG_HR_Users","SG_Finance_Users","SG_Operations_Users" |
  ForEach-Object {
    [PSCustomObject]@{
      Group = $_
      Members = (Get-ADGroupMember $_).Count
    }
  } | Format-Table
```

**Expected:** 8 / 7 / 8 / 7. If incorrect, inspect the specific group's `Get-ADGroupMember` output and compare against the CSV, including possible partial provisioning.

## 3. Network and DNS

**On CLIENT01:**

```cmd
ipconfig /all
ping 192.168.50.10
nslookup -type=A DC01.corp.example.test. 192.168.50.10
```

```powershell
Resolve-DnsName -Name DC01.corp.example.test -Type A -Server 192.168.50.10 -DnsOnly
Resolve-DnsName -Name 192.168.50.10 -Type PTR -Server 192.168.50.10 -DnsOnly
```

**On DC01:**

```powershell
Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.50.0
Get-DnsServerZone | Where-Object IsReverseLookupZone
Get-DnsServerResourceRecord -ZoneName "50.168.192.in-addr.arpa" -RRType PTR
```

Check the NIC's network name, DHCP lease, DNS server, route/gateway expectations, and both A/PTR queries independently. Remember the [remaining plain-`nslookup` timeout caveat](07-dhcp-and-dns-troubleshooting.md#root-cause-and-unresolved-condition).

## 4. Computer Group Policy and effective settings

**On CLIENT01 (elevated):**

```powershell
gpresult /r /scope computer

reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs

Get-NetFirewallProfile -PolicyStore ActiveStore |
  Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction

Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}' -Name Deny_Write
```

**Expected:** Baseline/Firewall/USB GPOs applied, `InactivityTimeoutSecs=600`, all three firewall profiles enabled with Block inbound / Allow outbound, `Deny_Write=1`.

## 5. SMB and folder ACLs

**On DC01:**

```powershell
"Finance","HR","IT","Operations" | ForEach-Object {
  Get-SmbShare -Name $_
  Get-SmbShareAccess -Name $_
  icacls "C:\CompanyShares\$_"
}
```

**On CLIENT01 under the actual employee identity:**

```cmd
whoami
dir \\DC01\Finance
dir \\DC01\IT
```

Never test a normal employee's access only through an elevated administrator shell. Effective access is subject to **both** NTFS and SMB permissions.

## 6. Security auditing and event triage

**On DC01:**

```powershell
gpresult /r /scope computer
auditpol /get /category:"Account Management"
auditpol /get /subcategory:"Kerberos Authentication Service"
```

| Event ID | Common case | Look for |
|---|---|---|
| 4720 | New domain user | Subject, new account, time |
| 4726 | Deleted domain user | Subject, deleted account |
| 4728 | Member joined global security group | Subject, member, group |
| 4730 | Global security group deleted | Subject, deleted group |
| 4771 | Failed Kerberos preauthentication | Target user, `Failure Code`, Client Address |
| 4740 | Account lockout | Locked account, Caller Computer Name |
| 4767 | Account unlock | Unlocking subject, target account |

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='Security'
  Id=4740
  StartTime=(Get-Date).AddDays(-1)
} | Select-Object -First 10 TimeCreated,Id,Message | Format-List
```

For other events, change `Id`. Filter to the relevant known test identity when necessary. Avoid deleting Security event logs to “clean up” after a test.

## 7. Incident workflow

1. **Verify symptoms:** Error text, username, source machine, timestamp.
2. **Scope:** Does DNS/IP work? Does the issue affect one user, department, or all clients?
3. **Collect evidence:** AD object state, GPO results, effective permissions, Security events.
4. **Identify likely cause:** Interpret a documented error code or missing access control; distinguish from a hypothesis.
5. **Remediate safely:** Limit changes to the relevant identity/policy; use least privilege.
6. **Retest:** Verify the original failed action is fixed and unauthorized actions stay blocked.
7. **Clean up:** Remove only controlled test objects; leave historic audit evidence intact.
8. **Document:** Commands, before/after outputs, what remains unresolved, and what should be monitored.

## 8. Reusable repository tools

- [`scripts/Verify-Lab.ps1`](../scripts/Verify-Lab.ps1): new **read-only** inventory and pass/fail checks on DC01.
- [`scripts/Export-SecurityEvents.ps1`](../scripts/Export-SecurityEvents.ps1): new **read-only Security log query**, with local CSV output if requested.
- [Scripts safety notes](../scripts/README.md).

**Credentials:** Do not commit plaintext passwords, actual employee personal data, VM snapshots, `.evtx` raw logs, or configuration exports with secrets. See [`.gitignore`](../.gitignore).
