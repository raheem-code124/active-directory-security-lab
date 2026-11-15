# Phase 8 — Domain controller security auditing

[← Phase 7](07-dhcp-and-dns-troubleshooting.md) · [Documentation index](README.md) · [Next: Authentication incidents →](09-authentication-and-account-lockout-incident.md)

## Objective

Configure domain controller audit policies and prove that Windows **actually logs** account and group changes. Audit configuration and an event being recorded are different claims; this phase verifies both.

## GPO deployment

1. Created a GPO named `GPO-DC-Security-Auditing`.
2. Edited the path **Computer Configuration → Policies → Windows Settings → Security Settings → Advanced Audit Policy Configuration → Audit Policies → Account Management**.
3. Enabled **Success and Failure** for:
   - Audit User Account Management
   - Audit Security Group Management
4. Linked the GPO specifically to `corp.example.test/Domain Controllers`.
5. Ran `gpupdate /force` on DC01 and verified applied GPOs via `gpresult /r /scope computer`.
6. Inspected effective auditing via `auditpol /get /category:"Account Management"`.

Evidence: [71 policy settings](../screenshots/71-dc-account-audit-policy-configured.png) · [72 GPO linked](../screenshots/72-dc-security-auditing-gpo-linked.png) · [73a applied policy](../screenshots/73a-dc-auditing-gpo-applied.png) · [73b effective audit settings](../screenshots/73b-dc-audit-policy-settings-verified.png).

```powershell
gpupdate /force
gpresult /r /scope computer
auditpol /get /category:"Account Management"
```

**Verified:** `GPO-DC-Security-Auditing` appeared under the computer's applied GPOs, and both selected audit subcategories showed `Success and Failure`. Other Account Management subcategories displayed `No Auditing`; this is intentional limited scope and not a claim of comprehensive auditing.

## Controlled event generation

All actions were performed by `CORP\Administrator` on the isolated domain controller, using temporary test objects.

| Event | Simulated action | Recorded details | Screenshot |
|---|---|---|---|
| **4720** | Created disabled account `audit.test` | Subject `CORP\Administrator`, target `audit.test`, 8:06:04 PM | [74a](../screenshots/74a-ad-user-creation-audit-event.png) · [74b](../screenshots/74b-security-event-4720-details.png) |
| **4726** | Deleted `audit.test` | Subject `CORP\Administrator`, target `audit.test`, 8:07:19 PM | [75](../screenshots/75-ad-user-deletion-audit-event.png) |
| **4728** | Added Alex Morgan (`amorgan`) to a temporary global security group | Subject `CORP\Administrator`, group `SG_Audit_Test`, member `CN=Alex Morgan,OU=IT,...`, 8:08:17 PM | [76](../screenshots/76-security-group-membership-audit-event.png) |
| **4730** | Deleted temporary `SG_Audit_Test` | Subject `CORP\Administrator`, group `SG_Audit_Test`, 8:17:08 PM | [77](../screenshots/77-security-group-deletion-audit-event.png) |

All timestamps above are from Windows VM screenshots dated **November 14, 2026**.

### Test commands (performed on DC01)

Create disabled user, then retrieve the creation event:

```powershell
New-ADUser -Name "Audit Test User" -SamAccountName "audit.test" `
  -Path "OU=IT,OU=Company,DC=corp,DC=example,DC=test" `
  -Enabled $false -Description "Temporary account for security auditing test"

Get-ADUser -Identity "audit.test" |
  Select-Object Name,SamAccountName,Enabled

Get-WinEvent -FilterHashtable @{LogName='Security';Id=4720;StartTime=(Get-Date).AddMinutes(-30)} |
  Where-Object {$_.Message -match 'audit\.test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

Delete user and retrieve deletion event:

```powershell
Remove-ADUser -Identity "audit.test" -Confirm:$false

Get-WinEvent -FilterHashtable @{LogName='Security';Id=4726;StartTime=(Get-Date).AddMinutes(-30)} |
  Where-Object {$_.Message -match 'audit\.test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

Group membership experiment and cleanup:

```powershell
New-ADGroup -Name "SG_Audit_Test" -SamAccountName "SG_Audit_Test" `
  -GroupScope Global -GroupCategory Security `
  -Path "OU=Groups,OU=Company,DC=corp,DC=example,DC=test"

Add-ADGroupMember -Identity "SG_Audit_Test" -Members "amorgan"

Get-WinEvent -FilterHashtable @{LogName='Security';Id=4728;StartTime=(Get-Date).AddMinutes(-30)} |
  Where-Object {$_.Message -match 'SG_Audit_Test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List

Remove-ADGroup -Identity "SG_Audit_Test" -Confirm:$false

Get-WinEvent -FilterHashtable @{LogName='Security';Id=4730;StartTime=(Get-Date).AddMinutes(-30)} |
  Where-Object {$_.Message -match 'SG_Audit_Test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

The test account was disabled so it could not be used for a normal sign-in. The temporary group had no departmental SMB privileges. Deleting the group removed Alex's temporary membership **without changing his membership in `SG_IT_Users`**.

## Analyst interpretation

The Subject fields identify the principal performing an action. Target/New Account and Group/Member fields identify **what changed**. Event timestamps support a sequence of actions. The emitted record is evidence of a Windows audit event, but **does not alone mean the action was unauthorized**.

In production, account and group change events should be sent to a monitored collection system, correlated with authorized change requests, and reviewed for unexpected privilege changes. This lab stops at Windows event generation and investigation using `Get-WinEvent`.

**Outcome:** GPO linked/applied and four account/group changes recorded.  
**Detailed studies:** [Account lifecycle](security-incident-reports/03-account-lifecycle-auditing.md) · [Group change auditing](security-incident-reports/04-group-membership-auditing.md).
