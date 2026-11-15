# Code review — original AD employee onboarding script

[← README](../README.md) · [Historical source](../scripts/historical/Create-Employees-v3.ps1) · [Provisioning walkthrough](02-active-directory-structure-and-automation.md)

## Evidence and provenance

The supplied archived `Create-Employees-v3.ps1` contains **79 lines**, **2,599 bytes**, and CRLF line endings. Its size agrees with the DC01 screenshot of `C:\ADLab\Scripts`, and its visible commands agree with Notepad captures of the original script. The original user-upload filename had the extra `.txt` extension, which was removed **without changing file bytes** for this repository. SHA-256 values for the original script and CSV were later captured on DC01 in [screenshot 0097](../screenshots/0097-original-files-sha256-verification.png). An independent comparison against the archived files confirmed **both hashes match**. This establishes file-byte identity at capture time, not authorship or which earlier runs used this version.

**No live execution was performed for this code review.** The observed 30-account final state is supported by [screenshot 88](../screenshots/0088-final-active-directory-security-verification.png), while the submitted source's CSV validation expects **28** records. No assumption is made about which process created the other two accounts.

## Logic actually present in the archived source

| Source operation | What it does | Evidence in code |
|---|---|---|
| `Import-Module ActiveDirectory` / `Import-Csv` | Loads AD commands and employee data from `C:\ADLab\Scripts\employees.csv` | Beginning of source |
| `$employees.Count -ne 28` | Fails if input count is not 28 | Initial preflight |
| `Group-Object Username` | Rejects duplicate usernames in the CSV | Initial preflight |
| Username regex and group lookup | Accepts usernames beginning with lowercase a-z and then 1–19 lowercase alphanumeric characters; maps IT/HR/Finance/Operations to global security groups | Initial preflight |
| `Get-ADUser` | Avoids creating an account if one already exists | Employee loop |
| `[guid]::NewGuid().ToString('N') + 'Aa9!'` | Creates a temporary account password value for newly created users | New account branch |
| `New-ADUser -Enabled $true -ChangePasswordAtLogon $true` | Creates enabled user and requires a password change when they successfully log on | New account branch |
| `Get-ADGroupMember` then `Add-ADGroupMember` | Adds missing membership and otherwise prints `VERIFIED` | Group branch |
| `try/catch` | Emits per-user warnings and continues the loop | Employee loop |

## Strengths that can be verified from source

- Prevents duplicate usernames in the imported CSV and stops when the record count is not the expected 28.
- Restricts the username format and department names before any account creation.
- Checks for existing accounts before creating new accounts, reducing duplicate creation on reruns.
- Checks group membership before adding an account, avoiding an unnecessary duplicate assignment.
- Uses `-ErrorAction Stop` for directory operations and emits readable progress for account/group actions.

## Specific weaknesses and how to fix them

| Severity | Location | Finding | Safer approach |
|---|---|---|---|
| **High** | Random password + `New-ADUser` | Random temporary passwords are never delivered to a user or an approved enrollment workflow. Created accounts are enabled, but the legitimate user has no documented way to retrieve the initial credential. | Create accounts disabled until authorized provisioning, then use an approved password setup/reset flow; never print secrets to CI/GitHub logs |
| **Medium** | `Get-ADUser` existing-account branch | Does not validate the existing account's department, OU, UPN, or intended group exclusivity; it can assign a department group to a misplaced account. | Preflight the expected OU and group, reject/migrate discrepancies only after approval |
| **Medium** | `catch` | Logs warnings but does not accumulate failures or exit nonzero, so callers may mistake a partially successful run for success. | Track failure counts, report each failed row, use nonzero exit when incomplete |
| **Medium** | CSV preflight | Does not check required column names, blank first/last names, character validity of names, or validate referenced OUs/groups before modifications begin. | Validate all required data and targets before writing |
| **Medium** | Mutating commands | No `SupportsShouldProcess`, `-WhatIf`, or dry-run mode to inspect planned changes. | Implement plan/preview first, then deliberate `-Apply` with confirmation |
| **Low** | `Get-ADGroupMember` in per-user loop | Repeatedly fetches the full member list for a group, which can be inefficient with large groups. | Query targeted memberships or cache groups when appropriate |
| **Low** | Fixed record count | The literal 28 is specific to this historical dataset, so it is not a general-purpose onboarding tool. | Make expected count configurable or validate against an explicit manifest |

The GUID-based password string is not a hardcoded secret. `ConvertTo-SecureString -AsPlainText` merely converts that generated value into a `SecureString` for the AD cmdlet; it does **not** provide secure delivery to users.

## Historical evidence versus future work

**Observed:** The [archived CSV](../scripts/historical/employees.csv) contains 28 fictional employee records; the source contains the checks shown; the initial automation had errors, later group counts were verified; the final directory had 30 users. See [screenshots 19a–22](evidence-index.md) and [88](../screenshots/0088-final-active-directory-security-verification.png).

**Not established:** That the additional two employees came from a particular script; that the original run handled every account without errors; that the generated passwords reached users; or that the new reference provisioning code ran against the original VM.

**Follow-up completed:** On a separate, disconnected clone, the newer [plan-first provisioning example](../scripts/Invoke-LabEmployeeProvisioning.ps1) passed plan-only, WhatIf, four disabled user creations with correct groups, and a plan-only rerun showing `ALREADY_CORRECT`. See [clone evidence](14-isolated-provisioning-validation.md). A live partial-failure recovery and second write-mode rerun remain untested; those scenarios are only mocked offline. The historical script was not rerun.
