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

Evidence: [51 folder structure](../screenshots/0051-department-file-folders-created.png).

## NTFS security design

For each department, broad inherited `CORP\Users` access was removed, and the matching departmental group was granted **Modify** rights. `Administrators` and `SYSTEM` retained **Full control**, with `CREATOR OWNER` inheritable to child items. Department folder ACLs were explicitly inspected through the Windows security UI and `icacls`.

| Folder | Allowed department group | Group NTFS rights |
|---|---|---|
| Finance | `CORP\SG_Finance_Users` | Modify |
| HR | `CORP\SG_HR_Users` | Modify |
| IT | `CORP\SG_IT_Users` | Modify |
| Operations | `CORP\SG_Operations_Users` | Modify |

Evidence: [52a Finance](../screenshots/0052a-finance-ntfs-permissions.png) · [52b HR](../screenshots/0052b-hr-ntfs-permissions.png) · [52c IT](../screenshots/0052c-it-ntfs-permissions.png) · [52d Operations](../screenshots/0052d-operations-ntfs-permissions.png) · [53 PowerShell ACL checks](../screenshots/0053-department-ntfs-permissions-verified.png).

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

Evidence: [54 Finance](../screenshots/0054-finance-network-share-created.png) · [55a remaining shares](../screenshots/0055a-department-network-shares-created.png) · [55b access matrix](../screenshots/0055b-department-network-shares-verified.png).

### NTFS vs. share permissions

When accessing `\\DC01\Finance` remotely, **both** the NTFS ACL and SMB share permissions matter. The effective access is constrained by the more restrictive result. The permission pair in this lab, `Modify` (NTFS) and `Change` (share), allows intended file creation/edits by the matching department group but blocks unauthorized groups.

## Positive and negative access tests

### Alex Morgan — IT user

On CLIENT01, `whoami` returned `corp\amorgan`.

```cmd
dir \\DC01\IT
dir \\DC01\Finance
```

**Observed:** IT share directory listing succeeded. Finance share listing returned `Access is denied.` Evidence: [56](../screenshots/0056-department-access-control-test.png).

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

Evidence: [57 Finance access](../screenshots/0057-finance-employee-access-verification.png) · [58 write/deny tests](../screenshots/0058-department-file-write-access-test.png).

## Troubleshooting approach

If an authorized user receives an access error:

1. Confirm identity with `whoami`.
2. Confirm the user's group membership (`Get-ADPrincipalGroupMembership` on DC01).
3. Check the SMB share ACL with `Get-SmbShareAccess`.
4. Check NTFS permissions with `icacls`.
5. Confirm path spelling, network reachability and DNS. A previous lab diagnostic produced an authentication/credential error after DHCP changes; later share access worked under an explicitly verified domain employee session.
6. Re-test authorized access and **unauthorized denial**, recording both outcomes.

## Observed conclusion

The original Phase 6 evidence covers two employee identities. The later follow-up expanded effective tests to **four identities × four shares**: 16 directory allow/deny checks, four permitted file create/read operations and four blocked unauthorized writes. This is still a representative four-user sample, **not** a 30-user full entitlement audit. See [four-department follow-up](13-department-access-control-follow-up.md).

[See the access-control troubleshooting case study](troubleshooting-case-studies/02-access-control-validation.md).


## Follow-up live user access tests — Steps 0124–0130

DC01 share and NTFS ACLs were revisited, CLIENT01 SMB connectivity was checked, and IT (`amorgan`), HR (`mpatel`), Finance (`sjohnson`) and Operations (`jlee`) employees each tested their own and the other three shares. Every authorized directory listing was allowed, all 12 unauthorized directory listings were denied, authorized write/read succeeded for each user, and one cross-department write attempt per user was denied. New temporary files were removed.

See the [full account-by-share matrix with direct evidence links](13-department-access-control-follow-up.md) and [HR password reset support ticket](support-tickets/AD-001-hr-password-reset.md).
