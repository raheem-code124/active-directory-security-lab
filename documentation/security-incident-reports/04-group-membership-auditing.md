# Security incident report 04 — Security group membership and deletion

**Case ID:** SEC-04  
**Type:** Controlled security-group change audit  
**Account:** `CORP\amorgan` (Alex Morgan)  
**Temporary group:** `CORP\SG_Audit_Test`, security-enabled global group.

## Objective

Prove that changes to security group membership and group existence can be reconstructed from DC01 audit logs.

The specific group was temporary and **did not provide privileged administration or departmental file-share rights**. We did not add Alex to Domain Admins.

## Group creation and modification

Created `SG_Audit_Test` under `OU=Groups,OU=Company,DC=corp,DC=example,DC=test`, then added Alex (`amorgan`). On DC01, queried Security Event ID **4728**.

```powershell
# Historical test commands — group was subsequently deleted.
New-ADGroup -Name "SG_Audit_Test" -SamAccountName "SG_Audit_Test" `
  -GroupScope Global -GroupCategory Security `
  -Path "OU=Groups,OU=Company,DC=corp,DC=example,DC=test"
Add-ADGroupMember -Identity "SG_Audit_Test" -Members "amorgan"

Get-WinEvent -FilterHashtable @{
  LogName='Security'; Id=4728; StartTime=(Get-Date).AddMinutes(-30)
} | Where-Object {$_.Message -match 'SG_Audit_Test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

**Observed 4728 (2026-11-14 20:08:17):**

| Field | Result |
|---|---|
| Description | Member added to security-enabled global group |
| Subject | `CORP\Administrator` |
| Member | `CN=Alex Morgan,OU=IT,OU=Company,DC=corp,DC=example,DC=test` |
| Group | `SG_Audit_Test` / `CORP` |

Evidence: [76 event 4728](../../screenshots/76-security-group-membership-audit-event.png).

## Cleanup and confirmation

Deleted the temporary group:

```powershell
Remove-ADGroup -Identity "SG_Audit_Test" -Confirm:$false
Get-ADGroup -Filter "SamAccountName -eq 'SG_Audit_Test'"
```

The lookup returned no group. DC01 then produced Event ID **4730**, at **2026-11-14 20:17:08**, with `CORP\Administrator` as Subject and `SG_Audit_Test` as deleted group.

Evidence: [77 event 4730](../../screenshots/77-security-group-deletion-audit-event.png).

Final production-like lab groups retained all expected members (IT 8, HR 7, Finance 8, Operations 7): [88 final validation](../../screenshots/88-final-active-directory-security-verification.png).

## What a security analyst learns

Changes to access groups can create or remove permissions even when no file ACL is edited. Event IDs 4728 and 4730 let analysts trace *who made a membership/deletion change* and *what object was affected*. The event IDs are for **security-enabled global groups**; domain local and universal groups use other related event IDs. A real security operations team should prioritize privileged groups and correlate events with approved changes.

**Result:** Group add and delete logged; test artifacts cleaned up.  
[Full Phase 8 report](../08-security-auditing-and-event-validation.md).
