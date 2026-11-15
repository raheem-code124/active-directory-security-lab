# PowerShell source, safety and reproducibility

The ORIGINAL employee onboarding source, Create-Employees-v3.ps1, was run inside DC01 but is not uploaded. **The newly published code below is a separately authored reconstruction and set of investigation helpers.** None are claimed to have been executed in the historical screenshots. No passwords or authentication tokens are committed.

| File | Does it modify AD? | Purpose |
|---|---|---|
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

## Original historical artifacts still needed

1. Export C:\ADLab\Scripts\Create-Employees-v3.ps1 and employees.csv from the VM.
2. Review source and data for credentials and unwanted personal information.
3. Keep the original named and labeled as the historical deployment. Compare its code to the new reconstruction; do not silently substitute one for the other.
4. Run the new offline tests and read-only DC01 checks, then publish actual results in a dated test record.

See [reviewer verification checklist](../documentation/reviewer-verification-checklist.md), [directory automation history](../documentation/02-active-directory-structure-and-automation.md), and [final limitations](../documentation/10-verification-and-limitations.md).
