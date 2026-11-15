# Security incident report 03 — Active Directory user lifecycle events

**Case ID:** SEC-03  
**Type:** Authorized test account creation and deletion  
**Target:** `CORP\audit.test`  
**GPO:** `GPO-DC-Security-Auditing` linked to Domain Controllers.

## Objective

Verify that DC01 logs the **who / what / when** of user account lifecycle changes, using an account incapable of a normal interactive login. This is a controlled audit experiment, not an unauthorized account incident.

## Control setup

Under Advanced Audit Policy Configuration → Audit Policies → Account Management, **Audit User Account Management** was configured for Success and Failure. The GPO was applied on DC01 via `gpupdate /force`. `gpresult` and `auditpol` verified effective settings ([71–73](../08-security-auditing-and-event-validation.md)).

## Event timeline

| Timestamp (VM local) | Event | Target | Initiator |
|---|---|---|---|
| 2026-11-14 20:06:04 | **4720** — A user account was created | `audit.test` | `CORP\Administrator` |
| 2026-11-14 20:07:19 | **4726** — A user account was deleted | `audit.test` | `CORP\Administrator` |

### Event 4720 — Account created

Created the account in the IT OU with `-Enabled $false`. Follow-up `Get-ADUser` showed `Enabled=False`.

Evidence: [74a event search](../../screenshots/74a-ad-user-creation-audit-event.png), [74b event details](../../screenshots/74b-security-event-4720-details.png).

The log identified a `New Account` called `audit.test` and **Subject** `CORP\Administrator`. The UAC-related fields were consistent with an account created disabled.

### Event 4726 — Account deleted

Deleted the temporary identity, then queried the Security log for 4726 matching `audit.test`. The event identified the deleted target and administrative subject. [Screenshot 75](../../screenshots/75-ad-user-deletion-audit-event.png).

## Investigative significance

These events can help answer whether an unexpected new identity was created, by which principal and at what time; they can also reveal unexpected deletions. An analyst should corroborate against provisioning tickets, identity workflows and other log sources.

**Result:** Both account lifecycle audit events generated; test identity removed.  
**Scope limitation:** The test did not demonstrate centralized log shipping, tamper resistance, SIEM alerts or user onboarding approval workflows.

[Full Phase 8 report](../08-security-auditing-and-event-validation.md).
