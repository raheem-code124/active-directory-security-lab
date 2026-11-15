# Enterprise Active Directory Security & Administration Lab

**Hands-on Windows Server, identity, endpoint security, access control, networking, and security event investigation**

Designed and tested an isolated Windows enterprise environment with AD DS, DNS/DHCP, automated user provisioning, Group Policy endpoint controls, role-based SMB/NTFS permissions, and security-event investigations. Validated both expected and denied access, traced failed Kerberos attempts to CLIENT01, reproduced an account lockout, and recovered the account with supporting event-log evidence.

> **Controlled lab simulation — not a production environment.** This project was built in Oracle VirtualBox using a dedicated isolated network, a Windows Server domain controller, a Windows client, and **30 fictional employee accounts**. Authentication failures, account changes, and account lockouts were **intentionally generated and investigated** for training. No real employer systems or employee accounts were used. The [architecture](diagrams/architecture.md), [107 numbered screenshots](documentation/evidence-index.md), and [incident reports](documentation/security-incident-reports/) document the lab setup and tests.

> **Project type:** Self-directed, isolated enterprise simulation | **Completed:** November 2026 | **Evidence:** 107 screenshots spanning steps 01–88  
> **Purpose:** Practice the tasks expected of IT support, systems/network administrators, and early-career security engineers. All users and incidents are fictional; this is **not a production deployment**.

![Architecture diagram](diagrams/architecture.svg)

## At a glance

| Area | Implemented and verified |
|---|---|
| Identity | Active Directory domain `corp.example.test` (`CORP`), one domain controller, 30 fictional employee accounts |
| Organization | Departmental OUs and four role-based security groups: IT (8), HR (7), Finance (8), Operations (7) |
| Endpoint | Domain-joined Windows 11 Enterprise client (`CLIENT01`); domain-user sign-in and applied computer policies |
| Endpoint controls | 600-second inactivity lock, Windows Defender Firewall rules, removable-disk write restriction |
| File access | Four SMB shares with department-specific share permissions and NTFS Modify permissions |
| Networking | Authorized DHCP server, `192.168.50.100–192.168.50.200` address pool, DNS option `192.168.50.10` |
| DNS | Forward A and reverse PTR lookups for `DC01`; investigated residual unqualified `nslookup` timeouts |
| Security monitoring | Account/group change auditing and Kerberos authentication auditing |
| Investigation | Verified Windows event IDs **4720, 4726, 4728, 4730, 4771, 4740, 4767** |
| Validation | Final check: 30 accounts, group counts 8/7/8/7, relevant audit settings still enabled |

The most valuable outcome is the **repeatable evidence**: configuration screenshots, PowerShell commands, both permitted and denied access tests, and event-log records showing what happened, when, to which account, and from which computer.

## Architecture

- **Hypervisor:** Oracle VirtualBox on a personal Windows computer.
- **Isolated lab network:** `CORP-LAB`, `192.168.50.0/24`. The lab DHCP service is intended only for this virtual network, not a home or office LAN.
- **DC01:** Windows Server 2025 evaluation, static `192.168.50.10`; AD DS, domain DNS, authorized DHCP, Group Policy management, and SMB file hosting.
- **CLIENT01:** Windows 11 Enterprise evaluation, initially configured statically for the domain join and later assigned `192.168.50.100/24` by DHCP. Uses `192.168.50.10` for DNS.
- **Domain:** `corp.example.test` / NetBIOS `CORP`.

See [the architecture diagram and network notes](diagrams/architecture.md) and the [full configuration reference](documentation/configuration-reference.md).

## What I built and tested

### 1. Domain services and identity

Installed AD DS and DNS, promoted DC01 to a domain controller, verified service and domain health, created departmental organizational units and security groups, and provisioned a 30-account fictional workforce from a CSV-backed PowerShell workflow. Membership checks produced **8 IT / 7 HR / 8 Finance / 7 Operations**. The user and group operations were tested against the actual lab directory.

[Read the identity and automation walkthrough](documentation/02-active-directory-structure-and-automation.md).

### 2. Domain-managed endpoint protection

Joined CLIENT01 to the domain, moved its computer object into the Workstations OU, and applied three workstation-focused Group Policy Objects. Verified policy application using `gpupdate` and `gpresult`, the 600-second inactivity setting through registry inspection and an actual lock-screen test, firewall profile enforcement, and removable-disk write restriction policy state.

[Read the endpoint policy report](documentation/05-workstation-group-policy-security.md).

### 3. Department access control

Created `C:\CompanyShares\{IT,HR,Finance,Operations}`, restricted each folder to the matching `SG_*_Users` group plus administrative/system principals, and exposed four SMB shares. Tested access as **`CORP\amorgan` (IT)** and **`CORP\sjohnson` (Finance)**. Authorized folder access and file creation succeeded; attempts to access or write to a different department's share were denied.

[Read the access-control report](documentation/06-department-file-shares-and-access-control.md).

### 4. DHCP/DNS services and troubleshooting

Installed and AD-authorized DHCP on DC01 and activated `192.168.50.100–200` within `192.168.50.0/24`. CLIENT01 received `192.168.50.100` and confirmed connectivity to DC01. Investigated DNS timeout behavior, created an AD-integrated reverse lookup zone `50.168.192.in-addr.arpa`, and added the PTR record for `192.168.50.10`.

**Known limitation:** Simple `nslookup DC01.corp.example.test` intermittently timed out before returning the correct address; explicit A/AAAA queries and the fully qualified query with a trailing dot answered without timeouts. The precise cause of the original timeouts was **not proven**.

[Read the DHCP/DNS troubleshooting case](documentation/07-dhcp-and-dns-troubleshooting.md).

### 5. Auditing and security investigations

Linked `GPO-DC-Security-Auditing` to the **Domain Controllers OU**. Verified Success and Failure auditing for User Account Management, Security Group Management, and Kerberos Authentication Service. Generated and inspected test events on DC01.

| Event ID | Controlled lab action | Evidence |
|---|---|---|
| 4720 | Created disabled `audit.test` account | [Creation event](screenshots/74b-security-event-4720-details.png) |
| 4726 | Deleted `audit.test` | [Deletion event](screenshots/75-ad-user-deletion-audit-event.png) |
| 4728 | Added Alex Morgan to temporary global security group | [Membership event](screenshots/76-security-group-membership-audit-event.png) |
| 4730 | Deleted the temporary group | [Group deletion event](screenshots/77-security-group-deletion-audit-event.png) |
| 4771 | Deliberately failed Kerberos preauthentication for `amorgan`; result code `0x18` | [Kerberos investigation](screenshots/80a-kerberos-failed-authentication-event.png) |
| 4740 | Locked `lockout.test` via three qualifying failures; source `CLIENT01` | [Lockout event](screenshots/85-account-lockout-event-4740-investigation.png) |
| 4767 | Unlocked `lockout.test` as `CORP\Administrator` | [Unlock event](screenshots/86-account-unlock-and-security-event-verification.png) |

A **fine-grained password policy** was used for the lockout experiment so the real lab employee accounts' default domain lockout threshold stayed unchanged. The test user and policy were deleted afterward.

[Read the account-lockout incident report](documentation/security-incident-reports/02-account-lockout-and-recovery.md).

## Technical documentation

| Section | Contents |
|---|---|
| [Documentation hub](documentation/README.md) | Ordered walkthrough, reports, and quick navigation |
| [Environment and domain controller](documentation/01-environment-and-domain-controller.md) | VM setup, static network, AD DS, DNS, initial validation |
| [Directory design and onboarding](documentation/02-active-directory-structure-and-automation.md) | OUs, security groups, CSV automation and correction steps |
| [Client domain join](documentation/03-client-domain-join.md) | Windows 11 build, DNS discovery, time sync, domain login |
| [Bulk provisioning and OU validation](documentation/04-bulk-provisioning-and-validation.md) | 30-user workforce, verification, workstation OU |
| [Workstation security GPOs](documentation/05-workstation-group-policy-security.md) | Auto-lock, firewall, USB write restriction |
| [NTFS and SMB access control](documentation/06-department-file-shares-and-access-control.md) | Share + NTFS permissions, positive/negative tests |
| [DHCP and DNS investigation](documentation/07-dhcp-and-dns-troubleshooting.md) | Scope/options, client lease, reverse zone, timeout caveat |
| [Domain controller security auditing](documentation/08-security-auditing-and-event-validation.md) | Audit policies and 4720/4726/4728/4730 |
| [Authentication/lockout investigation](documentation/09-authentication-and-account-lockout-incident.md) | 4771, 4740, 4767, scoped lockout policy |
| [Final checks and limitations](documentation/10-verification-and-limitations.md) | Outcome matrix, limitations, cleanup, next improvements |
| [Evidence index](documentation/evidence-index.md) | All 107 numbered images with direct links |
| [Operational runbook](documentation/operational-runbook.md) | Read-only health checks and investigation commands |
| [Security incident reports](documentation/security-incident-reports/) | Evidence-led incident summaries |
| [Troubleshooting case studies](documentation/troubleshooting-case-studies/) | Diagnostic reasoning and access-control tests |
| [Architecture](diagrams/architecture.md) | Editable Mermaid diagram and SVG |

## Skills practiced

**Active Directory Domain Services · Windows Server administration · DNS · DHCP · Group Policy · Kerberos authentication · PowerShell · CSV automation · RBAC · NTFS/SMB access control · Security event analysis · Incident triage · Windows 11 endpoint management · Technical documentation**

## Validation and honesty about scope

- This lab uses **one DC and one Windows client**, not a multi-site enterprise or a production high-availability design.
- The 30 accounts are **fictional test employees**. No live company identities or production data were managed.
- Event evidence demonstrates that configured auditing **records** activity; it does not establish a SIEM, continuous detection rule, automated response, or production alerting.
- Screenshots show actual lab output; sanitized reference scripts in this repository are **documentation/reusable checks**, not a claim that an unexported original onboarding script was committed.
- The DHCP network is intentionally isolated. No routing/internet access through a lab DHCP gateway is claimed.
- The remaining plain-`nslookup` timeout behavior is explicitly recorded in the troubleshooting report.

### Repository map

```text
README.md
configs/                     # Sanitized configuration details
diagrams/                    # Architecture SVG and Mermaid source
documentation/
  01-... through 10-...      # Chronological phase reports
  evidence-index.md          # 107 screenshot links
  operational-runbook.md     # Safe verification commands
  security-incident-reports/ # Security event case studies
  troubleshooting-case-studies/
notes/                       # Assumptions, known issues, review notes
screenshots/                 # Original numbered lab evidence
scripts/                     # Clearly labeled new verification/export helpers
```

---
*Built for practical learning. Technical claims can be checked against the linked output and numbered screenshots.*
