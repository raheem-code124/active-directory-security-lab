# Phase 2 — Directory structure, security groups, and initial automation

[← Phase 1](01-environment-and-domain-controller.md) · [Documentation index](README.md) · [Next: CLIENT01 →](03-client-domain-join.md)

## Objective

Replace a flat list of employees with a structure a small organization could manage: organizational units for departments, security groups for access rules, and a CSV-based onboarding process. Test automation, identify errors, and verify the directory after making corrections.

## Directory model

```text
corp.example.test
└── Company (OU)
    ├── Finance (OU)
    ├── HR (OU)
    ├── IT (OU)
    ├── Operations (OU)
    ├── Groups (OU)
    └── Workstations (OU; populated later)
```

Four global security groups were used throughout the lab:

- `SG_Finance_Users`
- `SG_HR_Users`
- `SG_IT_Users`
- `SG_Operations_Users`

**Why separate OUs and groups?** OUs organize directory objects and are convenient targets for Group Policy. Security groups, by contrast, are assigned to access control lists and file-share permissions. A folder is typically granted access to a security group, **not** to an OU.

### Evidence-backed build sequence

| Step | Action | Evidence |
|---|---|---|
| 13 | Created and inspected the `Company` OU hierarchy | [OU structure](../screenshots/13-active-directory-ou-structure.png) |
| 14 | Created department security groups | [Group structure](../screenshots/14-department-security-groups.png) |
| 15a–15b | Created and verified a Finance user and department membership through the GUI | [Account](../screenshots/15a-finance-employee-created.png) · [Group](../screenshots/15b-finance-group-membership.png) |
| 16a–16b | Repeated user creation and membership assignment in PowerShell | [Account](../screenshots/16a-powershell-user-created.png) · [Group](../screenshots/16b-powershell-group-membership.png) |
| 17a–17b | Built and checked an employee CSV input | [CSV](../screenshots/17a-employee-csv-created.png) · [Import check](../screenshots/17b-employee-csv-verification.png) |
| 18 | Wrote a PowerShell onboarding script | [Script](../screenshots/18-employee-automation-script-created.png) |
| 19a–19b | Investigated errors from an early bulk run and recovered from partial state | [Errors](../screenshots/19a-bulk-onboarding-errors.png) · [Recovery](../screenshots/19b-employee-account-recovery.png) |
| 20–21 | Checked and corrected department group membership | [Check](../screenshots/20-department-group-membership-verification.png) · [Correction](../screenshots/21-department-memberships-corrected.png) |
| 22 | Ran an improved script with create/verify and group-assignment output | [Improved script](../screenshots/22-improved-onboarding-script-verification.png) |

## CSV-backed provisioning

The onboarding input used fields including:

```csv
FirstName,LastName,Username,Department
Maya,Patel,mpatel,HR
Daniel,Kim,dkim,Finance
Jordan,Lee,jlee,Operations
Taylor,Reed,treed,IT
```

These four rows are **examples from the fictional lab dataset**, not a copy of the full 30-row employee file.

The working script `C:\ADLab\Scripts\Create-Employees-v3.ps1` used PowerShell's `Import-Csv` and the ActiveDirectory module. The captured version included checks for the expected CSV record count, duplicate usernames, valid usernames/departments, existing accounts, and department-to-group mapping. An administrator executed it inside DC01; the run printed `CREATED`, `VERIFIED`, and `GROUP ASSIGNED` messages. It was used to stabilize and verify the onboarding workflow.

Useful validation commands on a lab DC:

```powershell
# Confirm directory placement
Get-ADUser -Filter * -SearchBase "OU=Company,DC=corp,DC=example,DC=test" |
  Select-Object Name,SamAccountName,DistinguishedName

# Inspect per-department group membership
"SG_IT_Users","SG_HR_Users","SG_Finance_Users","SG_Operations_Users" |
  ForEach-Object {
    [PSCustomObject]@{
      Group   = $_
      Members = (Get-ADGroupMember -Identity $_).Count
    }
  } | Format-Table
```

## Troubleshooting and lessons

The first automation passes were **not perfectly clean**. Screenshots 19–21 document onboarding errors, repair of existing/partial directory objects, and a mismatch in group memberships. Rather than hiding those steps, this report retains them because partial-failure recovery and repeatable provisioning are important administrative skills.

The workflow was improved to check conditions before making changes and to confirm group membership afterward. The final directory was later expanded and revalidated in [Phase 4](04-bulk-provisioning-and-validation.md).

### Status after Phase 2

- Organizational units and department groups: created.
- Manual and PowerShell-based account creation: exercised.
- CSV-based bulk onboarding: exercised, debugged, and revised.
- Final 30-user outcome: confirmed later, not claimed as complete at this intermediate step.

**Source caveat:** The exact original `Create-Employees-v3.ps1` file was saved inside the VM and is **not present** in this repository. This write-up describes its visible behavior; no invented full script has been labeled as the original. See [scripts/README.md](../scripts/README.md).
