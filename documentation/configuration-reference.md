# Verified configuration reference

> A sanitized inventory derived from the completed lab and screenshots. Values not confirmed by evidence are marked *not recorded*; this is an educational one-domain, one-client implementation.

## Domain, machines, and network

| Item | Value |
|---|---|
| Lab network | VirtualBox isolated `CORP-LAB` network, `192.168.50.0/24` |
| DNS domain | `corp.example.test` |
| NetBIOS | `CORP` |
| Domain controller | `DC01` / `DC01.corp.example.test` |
| DC01 operating system | Windows Server 2025 evaluation |
| DC01 IPv4 | `192.168.50.10/24`, statically configured |
| Domain member | `CLIENT01`, Windows 11 Enterprise evaluation |
| Client network | Initially static `192.168.50.20`; later DHCP `192.168.50.100/24` |
| Client DNS | `192.168.50.10` |
| DHCP authorization | `DC01.corp.example.test`, `192.168.50.10` |
| DHCP scope | `192.168.50.0/24`, `192.168.50.100–192.168.50.200` |
| DHCP options | Option 006 DNS `192.168.50.10`; option 015 DNS domain `corp.example.test` |
| DHCP lease duration observed | Eight days |
| Reverse DNS zone | `50.168.192.in-addr.arpa`, primary, AD-integrated |
| PTR record | `192.168.50.10 → DC01.corp.example.test` |
| Default gateway | No router option configured or demonstrated for this isolated segment |

## Directory structure

```text
corp.example.test
├── Domain Controllers
│   └── DC01
└── Company
    ├── Finance
    ├── Groups
    ├── HR
    ├── IT
    ├── Operations
    └── Workstations
        └── CLIENT01
```

| Group | Department | Final members |
|---|---|---:|
| `SG_IT_Users` | IT | 8 |
| `SG_HR_Users` | HR | 7 |
| `SG_Finance_Users` | Finance | 8 |
| `SG_Operations_Users` | Operations | 7 |
| **Total** | **Fictional employees** | **30** |

The 30 users were checked with `Get-ADUser` scoped to `OU=Company`; membership counts were checked using `Get-ADGroupMember`. Group-count totals are consistent with final screenshot [88](../screenshots/0088-final-active-directory-security-verification.png).

## Group Policy

| GPO | Link | Verified settings |
|---|---|---|
| `GPO-Workstation-Security-Baseline` | `Company/Workstations` | Machine inactivity limit **600 seconds** |
| `GPO-Workstation-Firewall` | `Company/Workstations` | Domain/Private/Public firewall enabled; default inbound Block, outbound Allow |
| `GPO-Workstation-USB-Restriction` | `Company/Workstations` | Removable Disks: Deny write access = Enabled |
| `GPO-DC-Security-Auditing` | `Domain Controllers` | User Account Management, Security Group Management, Kerberos Authentication Service = Success and Failure |

`gpresult /r /scope computer` and `auditpol` were used to verify applied/computed settings; the USB policy was inspected at the registry path described in [Phase 5](05-workstation-group-policy-security.md).

## Department folder and SMB access model

Server folders: `C:\CompanyShares\Finance`, `HR`, `IT`, and `Operations`. SMB paths: `\\DC01\Finance`, `\\DC01\HR`, `\\DC01\IT`, `\\DC01\Operations`.

| Share/folder | Department principal | NTFS | Share permission |
|---|---|---|---|
| Finance | `CORP\SG_Finance_Users` | Modify | Change |
| HR | `CORP\SG_HR_Users` | Modify | Change |
| IT | `CORP\SG_IT_Users` | Modify | Change |
| Operations | `CORP\SG_Operations_Users` | Modify | Change |
| All four | Administrators/SYSTEM | Full control (NTFS); admins Full (SMB) | Administrative access |

Inherited broad Users permissions were removed from department folders; `CREATOR OWNER` appears as a child-object inheritance entry. Actual effective access must pass **both** NTFS and share checks. The lab tested `CORP\amorgan` (IT) and `CORP\sjohnson` (Finance) as positive/negative examples; it did not exhaustively sign in as every one of the 30 accounts.

## Temporary security exercises

| Exercise | Object/policy | Final disposition |
|---|---|---|
| User creation/deletion events | Disabled `audit.test` | Deleted |
| Security group audit | `SG_Audit_Test` with temporary `amorgan` membership | Group deleted |
| Account lockout | `lockout.test` | Unlocked, then deleted |
| Fine-grained lockout policy | `PSO-Lockout-Test`, threshold 3, 10-min lockout/observation | Deleted |
| Original domain lockout threshold | 0 (no automatic lockout) | Unchanged |

## Security event IDs

| ID | Meaning in this lab |
|---|---|
| 4720 | Test user created |
| 4726 | Test user deleted |
| 4728 | Member added to security-enabled global group |
| 4730 | Security-enabled global group deleted |
| 4771 | Kerberos preauthentication failed, code `0x18` |
| 4740 | Test user locked out; Caller Computer Name `CLIENT01` |
| 4767 | Test user unlocked by `CORP\Administrator` |

See [the incident reports](security-incident-reports/) and [evidence index](evidence-index.md).
