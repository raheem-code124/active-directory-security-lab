# PowerShell source, safety and reproducibility

The [historical `Create-Employees-v3.ps1`](historical/Create-Employees-v3.ps1) has now been uploaded from a user-supplied file matching the **2,599-byte size** shown in DC01. It is archived unchanged, with a [source provenance and safety note](historical/README.md) and [line-by-line technical review](../documentation/code-review-original-onboarding.md). This source was reported as run during the original lab; **the separately authored new tools below were not used for the historical screenshots**. The original [28-row CSV](historical/employees.csv) is archived alongside the historical script. No fixed account passwords or tokens are committed.

| File | Does it modify AD? | Purpose |
|---|---|---|
| [Historical Create-Employees-v3.ps1](historical/Create-Employees-v3.ps1) | **Yes — creating accounts and adding group memberships** | Archived supplied source, not an instruction to run it again |
| [EmployeeCsv.Validation.psm1](EmployeeCsv.Validation.psm1) | No | Offline four-column CSV validation, username and department checks, case-insensitive duplicate rejection |
| [Invoke-LabEmployeeProvisioning.ps1](Invoke-LabEmployeeProvisioning.ps1) | **Only with -Apply** | Preflight AD domain, OUs, groups and accounts; plan changes; create disabled new users; ensure correct group membership |
| [Verify-Lab.ps1](Verify-Lab.ps1) | No | Check directory, group, cleanup, DHCP, DNS and SMB state. Throws if any comparison fails or a section cannot run |
| [Export-SecurityEvents.ps1](Export-SecurityEvents.ps1) | No AD changes; optional local CSV write | Query selected Security event IDs, handle an empty time window |
| [Analyze-AuthenticationEvents.ps1](Analyze-AuthenticationEvents.ps1) | No | Read 4771 and 4740 from DC01 or synthetic CSV. Highlight repeated bad passwords; correlate nearby lockout by account/time |

## Offline synthetic tests

Run in Windows PowerShell 5.1+ or PowerShell 7 from the repository root (PowerShell must be installed). Tests use fictitious usernames and the documentation-only address 192.0.2.44. They require no network connection or AD permission.

~~~powershell
.\tests\Test-EmployeeCsv.ps1
.\tests\Test-AuthAnalyzer.ps1
.\tests\Test-RepoStructure.ps1
~~~

**Checks covered by the successful CI run:** all local Markdown links resolve, all 107 historical images exist, one synthetic authentication finding that correlates with an artificial lockout, correct mapping of four demo employees to groups, and rejection of a duplicate username. The offline scenarios **passed on GitHub-hosted PowerShell** in [this CI run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43669522297); they do not verify any live Windows Server or AD operation. If a test fails, correct the source and record the failure.

## Safe onboarding workflow on DC01

These are **new test records**, not the original 30-employee dataset. Requires the ActiveDirectory Windows PowerShell module and rights to query the isolated CORP lab.

~~~powershell
# Plan only; checks real domain/OU/group state, does not create users.
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv

# Explicit write mode with what-if output (still no changes).
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv -Apply -WhatIf

# Only after inspection and VM snapshot, explicitly authorize writes.
# New accounts are DISABLED, without passwords, until an admin provisions them.
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv -Apply
~~~

Safety properties: checks DNS root is exactly corp.example.test; checks the correct Company OU, department OUs and security groups; rejects invalid CSVs and duplicated usernames; refuses to move existing accounts from unexpected OUs; uses normal PowerShell confirmation; does not delete accounts or assign passwords. Re-running a partially completed plan should finish missing group membership. **This behavior still requires a live test before it can be called verified.**

## Read-only checks and log inspection on DC01

~~~powershell
.\scripts\Verify-Lab.ps1
.\scripts\Export-SecurityEvents.ps1 -HoursBack 24
.\scripts\Analyze-AuthenticationEvents.ps1 -HoursBack 4 -Threshold 3 -WindowMinutes 10
# Optional local CSV written only after reviewing contents:
.\scripts\Export-SecurityEvents.ps1 -HoursBack 24 -OutputPath 'C:\Temp\CORP-EventExport.csv'
~~~

The verification helper returns a failure if a section errors or results disagree with the expected baseline. It does not test a client user's real SMB access, USB writes, DNS timeout packet traces or GPO event delivery.

The authentication analyzer groups 4771 failures with status 0x18 by account and source IP in a time window and notes whether a 4740 event for that account occurs nearby. **It cannot by itself prove malicious activity or that the IP and caller computer are the same host**; confirm using environment evidence. No continuous collection or alerting is implemented.

## What remains to verify

1. **Source supplied and archived:** `Create-Employees-v3.ps1` is included as a 2,599-byte CRLF file; the byte count agrees with the DC01 screenshot. An independent hash comparison with the still-running VM has **not** been performed.
2. **Original data archived:** The original [28-record employee CSV](historical/employees.csv) is preserved (778 bytes, CRLF). The CSV does not explain the final two additional AD accounts.
3. **Historical versus new:** Keep the archived source unchanged; the newer safe provisioning example has different behavior and is not evidence that the historical job used that code.
4. **Runtime tests pending:** Run the read-only verification tools and the new example only in plan/WhatIf mode first; retain actual outputs.
5. **Do not re-run the archived original** on your established directory. It can create enabled accounts and change group membership.

See [reviewer verification checklist](../documentation/reviewer-verification-checklist.md), [directory automation history](../documentation/02-active-directory-structure-and-automation.md), and [final limitations](../documentation/10-verification-and-limitations.md).
