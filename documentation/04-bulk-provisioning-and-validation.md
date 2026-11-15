# Phase 4 — Complete the 30-user directory and validate memberships

[← Phase 3](03-client-domain-join.md) · [Documentation index](README.md) · [Next: GPOs →](05-workstation-group-policy-security.md)

## Objective

Bring the fictional employee directory to a known correct state after the initial automation exercises, then prepare to manage CLIENT01 using workstation-scoped Group Policy.

## CSV updates and automation

The final CSV at `C:\ADLab\Scripts\employees.csv` used columns `FirstName`, `LastName`, `Username`, and `Department`. A PowerShell check against the file showed **28 records** at one intermediate point. The dataset and deployment workflow were then expanded, and final validation confirmed **30 accounts** inside the `Company` OU.

This distinction matters: **28 is a documented intermediate count, 30 is the verified final state**. The history is intentionally kept because accurate reporting of changed requirements and verification is part of the work.

| Capture | Evidence |
|---|---|
| [37](../screenshots/37-expanded-employee-csv-verification.png) | Expanded CSV and record-count verification |
| [38](../screenshots/38-bulk-onboarding-script-prepared.png) | Improved CSV onboarding script preparation |
| [39](../screenshots/39-bulk-employee-onboarding-results.png) | Script execution showing created/verified users and group assignments |
| [40](../screenshots/40-bulk-employee-verification.png) | Count and department membership checks |
| [41](../screenshots/41-workstation-ou-configuration.png) | CLIENT01 computer object placed under Workstations |

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

The final values were verified again during [Phase 9's post-incident checks](../screenshots/88-final-active-directory-security-verification.png), after test account deletion, rather than being assumed from the CSV alone.

## Why validation was necessary

A successful `New-ADUser` call doesn't prove an account is in the correct OU or the right security group. Similarly, a script that prints `CREATED` could still leave partial changes after an error. This phase checked the **directory's state**: actual objects and memberships, not just console messages.

The Workstations OU also establishes clean Group Policy targeting. A GPO linked to `Company/Workstations` applies to CLIENT01's computer object without broadly linking it to the root of the domain.

## Reusability and limitations

The original onboarding script remains on the VM; its complete source was not exported to GitHub. The [PowerShell helpers](../scripts/README.md) in this repository are explicitly new reference/verification tools. The final employee dataset contains invented names and was not sourced from an actual employer.
