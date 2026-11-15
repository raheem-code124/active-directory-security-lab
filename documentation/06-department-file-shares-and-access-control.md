# Phase 6 — Departmental file sharing with NTFS and SMB permissions

[← Phase 5](05-workstation-group-policy-security.md) · [Documentation index](README.md) · [Next: DHCP/DNS →](07-dhcp-and-dns-troubleshooting.md)

## Objective

Provide shared files to employees while preventing them from accessing other departments' resources. Use **security groups** to control both NTFS folder permissions and SMB share permissions. Test both authorized and unauthorized user paths.

## Layout

```text
DC01  C:\CompanyShares\
      ├── Finance\     ↔  \\DC01\Finance
      ├── HR\          ↔  \\DC01\HR
      ├── IT\          ↔  \\DC01\IT
      └── Operations\  ↔  \\DC01\Operations
```

The lab created four department directories using PowerShell:

```powershell
New-Item -ItemType Directory -Path "C:\CompanyShares" -Force
"IT","HR","Finance","Operations" | ForEach-Object {
    New-Item -ItemType Directory -Path "C:\CompanyShares\$_" -Force
}
```

Evidence: [51 folder structure](../screenshots/51-department-file-folders-created.png).

## NTFS security design

For each department, broad inherited `CORP\Users` access was removed, and the matching departmental group was granted **Modify** rights. `Administrators` and `SYSTEM` retained **Full control**, with `CREATOR OWNER` inheritable to child items. Department folder ACLs were explicitly inspected through the Windows security UI and `icacls`.

| Folder | Allowed department group | Group NTFS rights |
|---|---|---|
| Finance | `CORP\SG_Finance_Users` | Modify |
| HR | `CORP\SG_HR_Users` | Modify |
| IT | `CORP\SG_IT_Users` | Modify |
| Operations | `CORP\SG_Operations_Users` | Modify |

Evidence: [52a Finance](../screenshots/52a-finance-ntfs-permissions.png) · [52b HR](../screenshots/52b-hr-ntfs-permissions.png) · [52c IT](../screenshots/52c-it-ntfs-permissions.png) · [52d Operations](../screenshots/52d-operations-ntfs-permissions.png) · [53 PowerShell ACL checks](../screenshots/53-department-ntfs-permissions-verified.png).

Example of the check run for each folder:

```powershell
icacls "C:\CompanyShares\Finance"
icacls "C:\CompanyShares\HR"
icacls "C:\CompanyShares\IT"
icacls "C:\CompanyShares\Operations"
```

The permission verification showed the department-specific group with `(OI)(CI)(M)`, enabling Modify for the folder, subfolders, and files. Broad Users permissions were absent from the final department ACLs.

**Security rationale:** A regular employee shouldn't gain HR or Finance data access merely by being signed into the domain. Group-based permission management avoids granting rights one person at a time and supports onboarding/offboarding.

## SMB sharing

Created four network shares backed by the corresponding NTFS folders. Each share grants the department group `Change` and `BUILTIN\Administrators` `Full`.

Example of the actual creation pattern:

```powershell
New-SmbShare -Name "Finance" -Path "C:\CompanyShares\Finance" `
  -ChangeAccess "CORP\SG_Finance_Users" `
  -FullAccess "BUILTIN\Administrators"

Get-SmbShareAccess -Name "Finance"
```

Equivalent commands were used for HR, IT, and Operations.

| Share | Share-level department permission | Admin permission |
|---|---|---|
| Finance | `SG_Finance_Users` — Change | Full |
| HR | `SG_HR_Users` — Change | Full |
| IT | `SG_IT_Users` — Change | Full |
| Operations | `SG_Operations_Users` — Change | Full |

Evidence: [54 Finance](../screenshots/54-finance-network-share-created.png) · [55a remaining shares](../screenshots/55a-department-network-shares-created.png) · [55b access matrix](../screenshots/55b-department-network-shares-verified.png).

### NTFS vs. share permissions

When accessing `\\DC01\Finance` remotely, **both** the NTFS ACL and SMB share permissions matter. The effective access is constrained by the more restrictive result. The permission pair in this lab, `Modify` (NTFS) and `Change` (share), allows intended file creation/edits by the matching department group but blocks unauthorized groups.

## Positive and negative access tests

### Alex Morgan — IT user

On CLIENT01, `whoami` returned `corp\amorgan`.

```cmd
dir \\DC01\IT
dir \\DC01\Finance
```

**Observed:** IT share directory listing succeeded. Finance share listing returned `Access is denied.` Evidence: [56](../screenshots/56-department-access-control-test.png).

### Sarah Johnson — Finance user

On CLIENT01, `whoami` returned `corp\sjohnson`.

```cmd
dir \\DC01\Finance
dir \\DC01\IT
echo Finance write test successful > \\DC01\Finance\finance-write-test.txt
type \\DC01\Finance\finance-write-test.txt
echo Unauthorized write test > \\DC01\IT\unauthorized-write-test.txt
```

**Observed:** Finance listing worked; IT listing was denied. The Finance file was created and read back successfully; attempted writing to the IT share returned `Access is denied.`

Evidence: [57 Finance access](../screenshots/57-finance-employee-access-verification.png) · [58 write/deny tests](../screenshots/58-department-file-write-access-test.png).

## Troubleshooting approach

If an authorized user receives an access error:

1. Confirm identity with `whoami`.
2. Confirm the user's group membership (`Get-ADPrincipalGroupMembership` on DC01).
3. Check the SMB share ACL with `Get-SmbShareAccess`.
4. Check NTFS permissions with `icacls`.
5. Confirm path spelling, network reachability and DNS. A previous lab diagnostic produced an authentication/credential error after DHCP changes; later share access worked under an explicitly verified domain employee session.
6. Re-test authorized access and **unauthorized denial**, recording both outcomes.

## Observed conclusion

Four department shares existed with consistent share and folder permissions. Two user identities were used for cross-department **allow/deny** checks, and one real file creation/readback test was captured. It is **not** claimed that every employee or every group permutation was tested.

[See the access-control troubleshooting case study](troubleshooting-case-studies/02-access-control-validation.md).
