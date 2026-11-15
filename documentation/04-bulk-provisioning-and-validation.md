# Phase 4 — Complete the 30-user directory and validate memberships

[← Phase 3](03-client-domain-join.md) · [Documentation index](README.md) · [Next: GPOs →](05-workstation-group-policy-security.md)

## Objective

Bring the fictional employee directory to a known correct state after the initial automation exercises, then prepare to manage CLIENT01 using workstation-scoped Group Policy.

## CSV updates and automation

The surviving CSV at `C:\ADLab\Scripts\employees.csv` has columns `FirstName`, `LastName`, `Username`, and `Department` and **28 records**, as verified in the later file check. The archived `Create-Employees-v3.ps1` also explicitly expects 28 records. Final AD verification found **30 accounts** inside the `Company` OU. Earlier screenshots [15a–15b](../screenshots/0015a-finance-employee-created.png) and [16a–16b](../screenshots/0016a-powershell-user-created.png) show the separate Finance account Sarah Johnson (`sjohnson`) and IT account Alex Morgan (`amorgan`) before the bulk CSV import. Both names are absent from the 28-row CSV. Their departmental assignments account for the one-member difference in Finance and IT; a complete username-by-username export of all 30 accounts is still needed for final reconciliation.

This distinction matters: **28 is the number of entries in the inspected CSV; 30 is the final AD account count.** These are different measurements, not proof that the CSV was expanded to 30 rows. See [historical source and code review](code-review-original-onboarding.md).

| Capture | Evidence |
|---|---|
| [37](../screenshots/0037-expanded-employee-csv-verification.png) | Expanded CSV and record-count verification |
| [38](../screenshots/0038-bulk-onboarding-script-prepared.png) | Improved CSV onboarding script preparation |
| [39](../screenshots/0039-bulk-employee-onboarding-results.png) | Script execution showing created/verified users and group assignments |
| [40](../screenshots/0040-bulk-employee-verification.png) | Count and department membership checks |
| [41](../screenshots/0041-workstation-ou-configuration.png) | CLIENT01 computer object placed under Workstations |

## Final verification

```powershell
(Get-ADUser -Filter * -SearchBase "OU=Company,DC=corp,DC=example,DC=test").Count
# Observed final result: 30

"IT","HR","Finance","Operations" | ForEach-Object {
  $group = "SG_${_}_Users"
  [PSCustomObject]@{
    Group   = $group
    Members = (Get-ADGroupMember $group).Count
  }
} | Format-Table
```

| Security group | Observed final membership count |
|---|---:|
| `SG_IT_Users` | 8 |
| `SG_HR_Users` | 7 |
| `SG_Finance_Users` | 8 |
| `SG_Operations_Users` | 7 |
| **Total** | **30** |

The final values were verified again during [Phase 9's post-incident checks](../screenshots/0088-final-active-directory-security-verification.png), after test account deletion, rather than being assumed from the CSV alone.

## Why validation was necessary

A successful `New-ADUser` call doesn't prove an account is in the correct OU or the right security group. Similarly, a script that prints `CREATED` could still leave partial changes after an error. This phase checked the **directory's state**: actual objects and memberships, not just console messages.

The Workstations OU also establishes clean Group Policy targeting. A GPO linked to `Company/Workstations` applies to CLIENT01's computer object without broadly linking it to the root of the domain.

## Reusability and limitations

The original 2,599-byte [onboarding script is now archived](../scripts/historical/Create-Employees-v3.ps1), along with a [code review](code-review-original-onboarding.md); the historical [28-row CSV is also archived](../scripts/historical/employees.csv). The separately documented [PowerShell helpers](../scripts/README.md) are **new** reference/verification tools. All employee identities in this lab are fictional.
