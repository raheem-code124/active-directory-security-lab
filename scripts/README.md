# PowerShell source, execution status, and safe reproduction

[Project overview](../README.md) · [Historical script review](../documentation/code-review-original-onboarding.md) · [Clone verification](../documentation/14-isolated-provisioning-validation.md)

## Historical files and newer helpers

| Source | Role | Observed execution state |
|---|---|---|
| [`historical/Create-Employees-v3.ps1`](historical/Create-Employees-v3.ps1) | Original 2,599-byte onboarding script | Archived from original lab evidence; do not rerun on established directory |
| [`historical/employees.csv`](historical/employees.csv) | Original 778-byte, 28-row CSV | Historical input; two more separately created users formed 30-account final roster |
| [`EmployeeCsv.Validation.psm1`](EmployeeCsv.Validation.psm1) | Strict CSV validator used by new script | Synthetic tests and actual clone execution |
| [`Invoke-LabEmployeeProvisioning.ps1`](Invoke-LabEmployeeProvisioning.ps1) | Later plan-first, disabled-account provisioning example | **Live tested on disconnected clone:** plan, WhatIf, Apply (four users), verification and plan-only rerun |
| [`Verify-Lab.ps1`](Verify-Lab.ps1) | Read-only AD/DHCP/DNS/SMB comparison helper | **21 checks passed** on original DC01, with stated scope limits |
| [`Test-LabRoster.ps1`](Test-LabRoster.ps1) | 28 archived CSV entries + two separately created identity reconciliation | **30 users live matched** on original DC01 |
| [`Analyze-AuthenticationEvents.ps1`](Analyze-AuthenticationEvents.ps1) | Analyze 4771/4740 from CSV or live events | Synthetic positive/negative CI tests; **not demonstrated on live DC01 logs** |
| [`Export-SecurityEvents.ps1`](Export-SecurityEvents.ps1) | Read local Security events or save CSV | Source available; runtime not verified |

## Safe provisioning use (only in a disposable isolated copy)

Requires the Windows PowerShell ActiveDirectory module and the fictional `corp.example.test` domain with Company departmental OUs/groups.

~~~powershell
# Default: read-only plan of requested actions
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv

# WhatIf: describe write actions without modifying directory
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv -Apply -WhatIf

# Controlled write: only after snapshot/isolation and manual review
.\scripts\Invoke-LabEmployeeProvisioning.ps1 -CsvPath .\tests\sample-employees.csv -Apply
~~~

The code checks the domain, target OUs/groups and existing account location before making changes. Its `-Apply` path creates new accounts **disabled and without passwords**. The clone test created `demo.it01`, `demo.hr01`, `demo.fin01` and `demo.ops01`, verified their group memberships and disabled flags, and saw `ALREADY_CORRECT` on a subsequent plan-only run.

**The original DC01 and the clone must never run on the same internal network with the copied domain-controller identity.** The clone used `CORP-LAB-TEST`, not the original `CORP-LAB`. [See execution evidence](../documentation/14-isolated-provisioning-validation.md).

## Read-only administrative verification

~~~powershell
.\scripts\Verify-Lab.ps1
.\scripts\Test-LabRoster.ps1 -Live
~~~

These newer scripts were run against the original DC01 in read-only mode. They confirmed the configuration in their implemented scope and the 30-person roster, but they do **not** test physical USB writes, every user's SMB effective access, actual GPO timing or full DNS timeout resolution.

## Offline tests

~~~powershell
.\tests\Test-EmployeeCsv.ps1
.\tests\Test-HistoricalCsv.ps1
.\tests\Test-RosterReconciliation.ps1
.\tests\Test-AuthAnalyzer.ps1
.\tests\Test-ProvisioningSafety.ps1
.\tests\Test-RepoStructure.ps1
~~~

The mocked provisioning safety tests include invalid domain/OU/group, unexpected existing-account location, disabled-account creation and partial group-add failures. A mock module is **not** real AD. See [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions) for current test status, and the [earlier successful CI run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43677960000) for previous results.

## Security and limitations

No real passwords or client credentials should be committed. Historical code can create enabled accounts and should not be rerun for demonstration. The new script was verified live only for the successful isolated-clone path, plus offline mocked failures. The authentication analyzer is not a continuously deployed SOC system; live Security-log execution is not documented.
