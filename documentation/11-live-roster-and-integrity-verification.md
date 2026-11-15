# Follow-up 11 — Live Active Directory roster and configuration verification

[Documentation hub](README.md) · [Complete image index](evidence-index.md)

## Objective and test scope

Revisit the **original** `corp.example.test` domain to check the archived onboarding inputs, record the actual 30-user directory contents, and validate domain/DHCP/DNS/SMB configuration with **read-only queries**. No historical onboarding code was rerun.

## Source provenance

PowerShell located `Create-Employees-v3.ps1` (2,599 bytes) and `employees.csv` (778 bytes) under `C:\ADLab\Scripts`. SHA-256 values for both files were captured on DC01. The corresponding archived copies are [the historical script](../scripts/historical/Create-Employees-v3.ps1) and [28-row historical CSV](../scripts/historical/employees.csv).

Evidence: [Source file locations](../screenshots/0096-original-ad-files-verification.png) · [On-VM SHA-256 hashes](../screenshots/0097-original-files-sha256-verification.png). A **cross-comparison** of the on-VM digest to the repository blob has not independently been recorded.

## Read-only domain verification

Verified directory root `corp.example.test` / NetBIOS `CORP`, 30 employees in the Company OU, four department group counts, temporary test-object cleanup, the active DHCP scope, configured DNS server option, reverse zone/PTR, and the four SMB share paths.

The updated [`Verify-Lab.ps1`](../scripts/Verify-Lab.ps1) produced:

~~~text
Checks: 21 completed, 0 mismatched, 0 sections errored.
Lab verification checks PASSED (limited to the checks listed above).
~~~

Evidence: [Required administrative cmdlets](../screenshots/0098-powershell-verification-prerequisites.png) · [21 live checks](../screenshots/0101-live-active-directory-verification.png) · [Saved verification transcript](../screenshots/0102-live-verification-output-saved.png).

The tool itself warns it **does not** establish CLIENT01 GPO behavior, user-token SMB effective permissions, or the root cause of DNS query timeouts.

## Thirty-account reconciliation

The archived CSV contains **28 fictional users**. Two separate accounts, `amorgan` (IT) and `sjohnson` (Finance), were created during the historical exercise. The read-only [`Test-LabRoster.ps1`](../scripts/Test-LabRoster.ps1) on DC01 compared the original 28 CSV rows plus those two known identities against the **live 30-user roster**.

| Department | Observed account count |
|---|---:|
| IT | 8 |
| HR | 7 |
| Finance | 8 |
| Operations | 7 |
| **Total** | **30** |

The live command reported **30 unique fictional users matched** and department counts **IT 8, HR 7, Finance 8, Operations 7**. It verifies directory identity and department membership at query time, **not logon access or effective file rights**.

Evidence: [30-user count](../screenshots/0092-active-directory-30-user-verification.png) · [Four groups](../screenshots/0093-active-directory-security-group-verification.png) · [Roster export](../screenshots/0094-active-directory-roster-export.png) · [Live roster pass](../screenshots/0105-live-account-reconciliation.png) · [Saved reconciliation output](../screenshots/0106-account-reconciliation-evidence-saved.png).

## Result and boundaries

**Passed:** 21 supported configuration comparisons and the live 30-user reconciliation. These newer read-only helpers are clearly separated from the historical original onboarding script, and the tests do not imply the post-lab provisioning implementation was responsible for creating the original directory.
