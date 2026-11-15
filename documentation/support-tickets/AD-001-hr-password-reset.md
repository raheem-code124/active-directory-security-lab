# AD-001 — Simulated HR account password-reset ticket

[Four-department testing](../13-department-access-control-follow-up.md) · [Screenshot index](../evidence-index.md)

| Field | Recorded value |
|---|---|
| Ticket ID | AD-001 — fictional lab help-desk incident |
| Date | November 15, 2026 |
| Category | Account access / identity management |
| Affected account | Maya Patel — `CORP\mpatel` |
| Department | HR |
| Environment | Isolated `corp.example.test` lab |
| Outcome | Resolved and verified within the training exercise |

## Issue description

The lab operator did not have a working password for the fictional HR employee account when beginning departmental access tests. The purpose of this exercise was to restore lab account access and verify that its departmental rights were correct. This was **not** a real employee-submitted ticket.

## Investigation

On DC01, an Active Directory query showed ~mpatel~ under `OU=HR,OU=Company`. The account was `Enabled=True`, `LockedOut=False` and belonged to `Domain Users` and `SG_HR_Users`. These observations did not indicate a disabled account or active lockout.

Evidence: [Account and group checks](../../screenshots/0128a-hr-account-pre-reset-verification.png).

## Resolution and verification

1. Located the account in Active Directory Users and Computers.
2. Performed an authorized password reset in the isolated lab.
3. Captured the dialog confirming the password was changed.
4. Logged in to CLIENT01 as `CORP\mpatel` and checked the signed-in identity/group token.
5. Confirmed the HR share was accessible and IT, Finance, Operations directories were denied.
6. Created and read a file inside the HR share; attempted a write to IT and received `Access is denied`.
7. Deleted the HR test file; final listing showed no files remaining.

Evidence: [Successful ADUC reset](../../screenshots/0128b-hr-password-reset-confirmation.png) · [Domain login](../../screenshots/0128c-hr-password-reset-login-verification.png) · [Department access matrix](../../screenshots/0128d-hr-employee-share-access-test.png) · [HR file write/read](../../screenshots/0128e-hr-employee-write-access-verification.png) · [Denied cross-department write and cleanup](../../screenshots/0128f-hr-unauthorized-write-and-cleanup.png).

## Root cause, scope and safeguards

The confirmed condition was **unavailable working credentials to the lab operator**. The underlying reason earlier credentials were rejected was not independently established. Resetting the lab password restored domain login, and subsequent tests confirmed that the account's observed HR rights worked while cross-department access remained blocked.

The exercise does not claim workplace authorization checks, a real identity-verification workflow, a production outage, or access to any real person's account. No plaintext password was committed.
