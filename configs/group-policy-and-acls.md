# Configuration matrix — CORP lab (sanitized)

## Policy-to-scope map

| GPO | Linked OU | Policy path or feature | Observed setting |
|---|---|---|---|
| GPO-Workstation-Security-Baseline | Company/Workstations | Interactive logon: Machine inactivity limit | 600 seconds |
| GPO-Workstation-Firewall | Company/Workstations | Windows Defender Firewall with Advanced Security | Domain/Private/Public enabled, inbound Block, outbound Allow |
| GPO-Workstation-USB-Restriction | Company/Workstations | Administrative Templates/System/Removable Storage Access | Removable Disks: Deny write access = Enabled |
| GPO-DC-Security-Auditing | Domain Controllers | Advanced Audit Policy → Account Management | User Account Management + Security Group Management = Success/Failure |
| GPO-DC-Security-Auditing | Domain Controllers | Advanced Audit Policy → Account Logon | Kerberos Authentication Service = Success/Failure |

**Computer policy evidence:** [43](../screenshots/43-workstation-gpo-application-verification.png), [47a](../screenshots/47a-workstation-gpo-verification.png), [47b](../screenshots/47b-workstation-firewall-verification.png), [50a](../screenshots/50a-usb-restriction-gpo-applied.png), [50b](../screenshots/50b-usb-write-restriction-registry-verified.png), [73b](../screenshots/73b-dc-audit-policy-settings-verified.png), [78](../screenshots/78-kerberos-authentication-auditing-enabled.png).

## NTFS access-control model

| Local path | Security group | NTFS rights | SMB share rights |
|---|---|---|---|
| C:\CompanyShares\IT | CORP\SG_IT_Users | Modify (OI/CI) | Change |
| C:\CompanyShares\HR | CORP\SG_HR_Users | Modify (OI/CI) | Change |
| C:\CompanyShares\Finance | CORP\SG_Finance_Users | Modify (OI/CI) | Change |
| C:\CompanyShares\Operations | CORP\SG_Operations_Users | Modify (OI/CI) | Change |

Administrators and SYSTEM retained Full control at the file-system level. Administrators had Full SMB share access. The parent `C:\CompanyShares` and each child folder were treated separately to avoid inherited broad user access.

**Server-side ACL evidence:** [52a–d](../documentation/06-department-file-shares-and-access-control.md#ntfs-security-design) and [53](../screenshots/53-department-ntfs-permissions-verified.png). **User-side test evidence:** [56](../screenshots/56-department-access-control-test.png), [57](../screenshots/57-finance-employee-access-verification.png), [58](../screenshots/58-department-file-write-access-test.png).

## Network configuration

| Item | Value |
|---|---|
| DC01 address | 192.168.50.10/24 |
| DHCP server authorized in AD | DC01.corp.example.test |
| Scope | 192.168.50.0/24 |
| DHCP range | 192.168.50.100–192.168.50.200 |
| Scope DNS | 192.168.50.10 |
| Scope suffix | corp.example.test |
| CLIENT01 assigned | 192.168.50.100 |
| Reverse zone | 50.168.192.in-addr.arpa |
| PTR for DC01 | 10 → DC01.corp.example.test |

**No default router was demonstrated**, because this project uses an isolated virtual network. The original non-trailing-dot `nslookup` timeout was not conclusively fixed; see [Phase 7](../documentation/07-dhcp-and-dns-troubleshooting.md).

## Temporary lockout policy (deleted after test)

`PSO-Lockout-Test`: complexity enabled, 12-character minimum, 5-password history, min age 0, max age 90 days, lockout threshold 3, duration 10 minutes, observation window 10 minutes, reversible encryption disabled. Applied directly to `lockout.test`, then both objects were removed. The domain-wide threshold remained 0.

**Evidence:** [83](../screenshots/83-test-account-lockout-policy-configured.png), [84b](../screenshots/84b-account-lockout-confirmed.png), [87](../screenshots/87-lockout-test-environment-cleanup.png).

**This document is a human-readable record, not an exported security baseline or compliance certification.**
