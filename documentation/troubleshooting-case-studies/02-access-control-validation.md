# Troubleshooting case 02 — Cross-department access restrictions

**Environment:** Four SMB shares on `DC01`, domain-joined `CLIENT01`, and departmental global security groups.

## Goal

Demonstrate both sides of role-based access: an employee can work in their department's folder but cannot browse or write another department's folder.

## Access model

| Department | Group | Local path | UNC |
|---|---|---|---|
| IT | `SG_IT_Users` | `C:\CompanyShares\IT` | `\\DC01\IT` |
| Finance | `SG_Finance_Users` | `C:\CompanyShares\Finance` | `\\DC01\Finance` |
| HR | `SG_HR_Users` | `C:\CompanyShares\HR` | `\\DC01\HR` |
| Operations | `SG_Operations_Users` | `C:\CompanyShares\Operations` | `\\DC01\Operations` |

Each folder grants its department group Modify (NTFS), and each SMB share grants that department group Change. Administrative principals retain necessary full access.

## Test 1 — Alex Morgan (IT)

```cmd
whoami
dir \\DC01\IT
dir \\DC01\Finance
```

**Observed:** `corp\amorgan`; IT directory accessible; Finance directory denied. [Screenshot 56](../../screenshots/0056-department-access-control-test.png).

## Test 2 — Sarah Johnson (Finance)

```cmd
whoami
dir \\DC01\Finance
dir \\DC01\IT
echo Finance write test successful > \\DC01\Finance\finance-write-test.txt
type \\DC01\Finance\finance-write-test.txt
echo Unauthorized write test > \\DC01\IT\unauthorized-write-test.txt
```

**Observed:** `corp\sjohnson`; Finance listing and file write/read succeeded; IT listing and unauthorized file write were denied. [Screenshot 57](../../screenshots/0057-finance-employee-access-verification.png) · [Screenshot 58](../../screenshots/0058-department-file-write-access-test.png).

## How an administrator should investigate a permissions ticket

1. Confirm current session with `whoami`.
2. Verify account/group assignment in AD.
3. Check the share with `Get-SmbShareAccess -Name Finance`.
4. Check NTFS with `icacls "C:\CompanyShares\Finance"`.
5. Consider that NTFS and SMB rights both apply; the effective result is limited by both.
6. Re-test as the actual non-admin user; administrator success isn't proof that employee access works.
7. Record successful allowed actions and the precise denied command.

## What this did *not* test

It did not exhaustively run 30 employee logins or test all 16 possible department-to-share pairs. The demonstrated end-to-end identities are Alex and Sarah; the server-side configuration was checked for all four departments. It also did not build DFS or a separate file-server VM.

[Full Phase 6 report](../06-department-file-shares-and-access-control.md).
