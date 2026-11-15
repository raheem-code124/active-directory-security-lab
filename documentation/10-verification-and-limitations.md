# Phase 9 closeout — Final verification, limitations, and next steps

[← Phase 9](09-authentication-and-account-lockout-incident.md) · [Documentation index](README.md) · [Main README](../README.md)

## Final integrity check — November 14, 2026

After the authentication and lockout experiments, the domain controller was checked again in administrator PowerShell.

```powershell
(Get-ADUser -Filter * -SearchBase "OU=Company,DC=corp,DC=example,DC=test").Count

"SG_IT_Users","SG_HR_Users","SG_Finance_Users","SG_Operations_Users" |
  ForEach-Object {
    [PSCustomObject]@{
      Group   = $_
      Members = (Get-ADGroupMember -Identity $_).Count
    }
  } | Format-Table

auditpol /get /category:"Account Management"
auditpol /get /subcategory:"Kerberos Authentication Service"
```

### Actual result

| Control / metric | Verified outcome |
|---|---|
| Users under Company OU | **30** |
| IT security group | **8** members |
| HR security group | **7** members |
| Finance security group | **8** members |
| Operations security group | **7** members |
| Security Group Management auditing | Success and Failure |
| User Account Management auditing | Success and Failure |
| Kerberos Authentication Service auditing | Success and Failure |
| Temporary `audit.test` | Deleted |
| Temporary `SG_Audit_Test` | Deleted |
| Temporary `lockout.test` | Deleted |
| Temporary `PSO-Lockout-Test` | Deleted |

**Primary proof:** [Screenshot 88 — final AD/security verification](../screenshots/88-final-active-directory-security-verification.png). Test-object removals are documented separately in [75](../screenshots/75-ad-user-deletion-audit-event.png), [77](../screenshots/77-security-group-deletion-audit-event.png), and [87](../screenshots/87-lockout-test-environment-cleanup.png).

## Control test matrix

| Test | Outcome | Evidence |
|---|---|---|
| AD DS and DNS services running | Pass | [10b](../screenshots/10b-active-directory-services.png) |
| Domain join and employee sign-in | Pass | [34](../screenshots/34-client01-domain-join-success.png), [35](../screenshots/35-domain-employee-login-verification.png) |
| 600-sec lock setting and observed lock screen (elapsed time not measured independently) | Configured + observed | [43](../screenshots/43-workstation-gpo-application-verification.png), [44](../screenshots/44-workstation-auto-lock-test.png) |
| Firewall profiles enabled/default rules | Pass | [47b](../screenshots/47b-workstation-firewall-verification.png) |
| Removable disk deny-write *policy applied* | Pass | [50b](../screenshots/50b-usb-write-restriction-registry-verified.png) |
| Physical USB write attempt blocked | Not tested | — |
| IT allowed, Finance denied (as Alex) | Pass | [56](../screenshots/56-department-access-control-test.png) |
| Finance file write allowed, IT write denied (as Sarah) | Pass | [58](../screenshots/58-department-file-write-access-test.png) |
| DHCP lease/DNS option delivered | Pass | [63](../screenshots/63-client-dhcp-address-assignment.png) |
| Reverse PTR for DC01 fixed | Pass | [68](../screenshots/68-dns-repair-verification.png) |
| Unqualified ordinary `nslookup` fully timeout-free | **Not established** | [68–70](07-dhcp-and-dns-troubleshooting.md#re-test-after-the-change) |
| Account lifecycle events recorded | Pass | [74](../screenshots/74b-security-event-4720-details.png), [75](../screenshots/75-ad-user-deletion-audit-event.png) |
| Group membership/deletion events recorded | Pass | [76](../screenshots/76-security-group-membership-audit-event.png), [77](../screenshots/77-security-group-deletion-audit-event.png) |
| Failed Kerberos preauthentication 4771 | Pass | [80a](../screenshots/80a-kerberos-failed-authentication-event.png) |
| Account lockout 4740, unlock 4767 | Pass | [85](../screenshots/85-account-lockout-event-4740-investigation.png), [86](../screenshots/86-account-unlock-and-security-event-verification.png) |
| User/group/audit final state | Pass | [88](../screenshots/88-final-active-directory-security-verification.png) |

## Confirmed project limitations

1. **Small scope:** One DC and one domain-joined Windows client. No replication or failover testing.
2. **Simulated employees:** All 30 users belong to a fictional lab organization.
3. **No actual enterprise environment:** All network services ran on an isolated VirtualBox network.
4. **No SIEM/EDR:** Windows Security logs were queried locally; automatic alerting or endpoint detection wasn't deployed.
5. **USB test limitation:** Registry and GPO verified, but no physical/virtual USB write attempt recorded.
6. **DNS issue still open:** The A and PTR records worked, but some ordinary `nslookup` commands showed timeouts.
7. **Not every employee tested:** Actual SMB positive/negative tests used Alex Morgan and Sarah Johnson; no 30-user sign-in matrix.
8. **Original script not exported:** The working CSV provisioning script ran inside the VM but has not been included as a verified byte-for-byte source file. A separately labeled new provisioning reconstruction and offline CSV validator are published but have not been used to reproduce the historical run.
9. **Evaluation software:** Windows Server and Windows 11 Enterprise were evaluation systems.
10. **No external pentest or malware:** Authentication and group-change incidents were controlled lab events.

## Future improvements (not yet implemented)

- Enable more targeted audit subcategories and an appropriate central collection/alerting pipeline.
- Execute, test, and refine the newly published local 4771/4740 correlation helper against actual DC01 logs. It is not a deployed continuous alerting system.
- Capture DNS traffic to isolate the intermittent timeout behavior.
- Test a removable media write denial with a dedicated virtual USB disk.
- Export the actual onboarding script and compare its source with the newly written example; run a real idempotency test before claiming reproducible automation.
- Add a second member workstation and second DC to explore scale and replication.
- Set a dedicated file server and compare access with effective-rights reporting.
- Document recoverability using a controlled DC backup/restore lab.

## Resume / interview talking points (grounded)

> Built an isolated two-VM Active Directory lab with 30 fictional domain users, role-based file shares, three workstation security GPOs, DHCP/DNS services, and Windows security auditing. Investigated failed Kerberos authentication and an account lockout through Events 4771/4740, traced the source to CLIENT01, unlocked the account, and verified final system state.

A strong interview answer should discuss **why** group-based access, DNS, GPO scope, and audit evidence were chosen; it should also openly mention the unresolved DNS behavior and USB test limitation instead of overstating project scope.

[Review every evidence file](evidence-index.md) · [Read the runbook](operational-runbook.md).


## Post-lab source review status (new work)

After the historical screenshots, new read-only checks, a plan-first disabled-user provisioning example, an authentication-correlation helper, and synthetic offline test fixtures were added to the repository. **Their presence is not proof they ran successfully against DC01 or that the original onboarding script was recovered.**

| Post-lab artifact | Source review availability | Actual execution |
|---|---|---|
| [Provisioning example and CSV validator](../scripts/README.md) | Readable source | **Pending Windows/AD test** |
| [Synthetic validation tests](../tests/) | Test code and artificial CSV inputs | **Pending PowerShell run** |
| [Updated Verify-Lab.ps1](../scripts/Verify-Lab.ps1) | Fails on mismatch or incomplete checks | **Pending DC01 run** |
| [Authentication analyzer](../scripts/Analyze-AuthenticationEvents.ps1) | Correlation logic and fixture | **Pending real-log test** |

Use [reviewer verification checklist](reviewer-verification-checklist.md) to record the next genuine tests and remaining unverified claims.
