# Enterprise Active Directory Security & Administration Lab

**Windows Server 2025 · AD DS · DNS/DHCP · PowerShell · Group Policy · SMB/NTFS · Kerberos event investigation**

Designed and tested an isolated Windows domain with Active Directory, DNS/DHCP, CSV-backed user onboarding, domain-managed endpoint controls, departmental file permissions, and security-event investigations. Validated both allowed and denied access, investigated failed Kerberos preauthentication from CLIENT01, triggered a scoped test-account lockout, and verified administrator recovery using Windows Security events.

> **Controlled training environment.** Built in Oracle VirtualBox with one Windows Server domain controller (DC01), one Windows 11 client (CLIENT01), and 30 fictional employee accounts on an isolated virtual network. Failed sign-ins, account/group changes, and account lockouts were intentionally simulated. No real organization, customers, credentials, or production infrastructure were involved. **This is not a production security deployment.**

![Architecture: two VMs on an isolated CORP-LAB network](diagrams/architecture.svg)

## Start here: five evidence-backed results

| Question a reviewer should ask | Observed result | Primary evidence and explanation |
|---|---|---|
| Does the domain actually work? | CLIENT01 joined corp.example.test; employee domain sign-in demonstrated | [Domain join screenshot 34](screenshots/34-client01-domain-join-success.png) · [Phase 3](documentation/03-client-domain-join.md) |
| Was user provisioning completed? | 30 fictional users; security-group counts **IT 8 / HR 7 / Finance 8 / Operations 7** | [User/group verification 40](screenshots/40-bulk-employee-verification.png) · [Provisioning errors 19a](screenshots/19a-bulk-onboarding-errors.png) · [Phase 2](documentation/02-active-directory-structure-and-automation.md) |
| Did central endpoint settings apply? | Three workstation GPOs applied; firewall profiles Block inbound/Allow outbound; USB deny-write registry value 1 | [Firewall 47b](screenshots/47b-workstation-firewall-verification.png) · [USB 50b](screenshots/50b-usb-write-restriction-registry-verified.png) · [Phase 5](documentation/05-workstation-group-policy-security.md) |
| Did group-based access work? | IT user accessed IT share and was denied Finance; Finance user accessed/wrote Finance and was denied IT | [Share/NTFS setup 53](screenshots/53-department-ntfs-permissions-verified.png) · [Client tests 56–58](documentation/06-department-file-shares-and-access-control.md#positive-and-negative-access-tests) |
| Was an authentication incident investigated end to end? | Event **4771** code **0x18** for amorgan from 192.168.50.100; test user lockout **4740** from CLIENT01; admin unlock **4767** | [4771 event 80a](screenshots/80a-kerberos-failed-authentication-event.png) · [4740 event 85](screenshots/85-account-lockout-event-4740-investigation.png) · [4767 event 86](screenshots/86-account-unlock-and-security-event-verification.png) · [Incident report](documentation/security-incident-reports/02-account-lockout-and-recovery.md) |

**Interpretation:** These links document observed configurations, commands, and test outcomes. The screenshots are evidence of a lab session; they are not proof of the author's independence, production readiness, or a successful run of every reference script now published.

## Environment and design

| Component | Lab implementation |
|---|---|
| Virtualization | Oracle VirtualBox; isolated network named CORP-LAB |
| Domain controller | DC01, Windows Server 2025 Evaluation, static 192.168.50.10/24 |
| Domain | corp.example.test (CORP) |
| Workstation | CLIENT01, Windows 11 Enterprise Evaluation, DHCP-assigned 192.168.50.100/24 |
| Directory | Company OU, IT/HR/Finance/Operations sub-OUs, four global security groups, Workstations OU |
| Workstation GPOs | 600-second inactivity setting; enabled firewall profiles with default inbound Block; removable-disk deny-write policy |
| Department shares | Four SMB shares; matching group receives SMB Change and NTFS Modify; admins retain Full |
| Network services | Authorized DHCP range 192.168.50.100–200; DNS 192.168.50.10; reverse PTR for DC01 |
| Audit trail | Windows Security events 4720, 4726, 4728, 4730, 4771, 4740, 4767 |

**Design tradeoff:** DC01 also hosts DHCP and the four departmental SMB shares because this is a two-VM lab. In a production-style design, I would separate the file-server workload from the domain controller's privileged identity boundary. No redundant DC, backup recovery, SIEM, EDR, centralized log collection, or internet routing was built. See [architecture decisions and trust-boundary limitations](diagrams/architecture.md).

## Technical case studies

| Topic | Read the evidence-led report |
|---|---|
| CSV onboarding errors and department memberships | [Directory structure and automation](documentation/02-active-directory-structure-and-automation.md) |
| Policy scoping and workstation enforcement | [Group Policy controls](documentation/05-workstation-group-policy-security.md) |
| Permitted vs. denied SMB and NTFS access | [Department access-control investigation](documentation/troubleshooting-case-studies/02-access-control-validation.md) |
| DHCP lease and incomplete DNS timeout investigation | [DHCP/DNS troubleshooting](documentation/07-dhcp-and-dns-troubleshooting.md) |
| Group/user lifecycle auditing | [Account lifecycle events](documentation/security-incident-reports/03-account-lifecycle-auditing.md) · [Group-change events](documentation/security-incident-reports/04-group-membership-auditing.md) |
| Kerberos error 0x18 | [Failed Kerberos preauthentication](documentation/security-incident-reports/01-kerberos-failed-logon.md) |
| Lockout, event correlation and recovery | [Account lockout case](documentation/security-incident-reports/02-account-lockout-and-recovery.md) |

[All nine phases](documentation/README.md) · [107 screenshots indexed by milestone](documentation/evidence-index.md) · [Final verification matrix](documentation/10-verification-and-limitations.md) · [Reviewer reproduction checklist](documentation/reviewer-verification-checklist.md)

## Source code and repeatability

The [original onboarding script supplied from DC01](scripts/historical/Create-Employees-v3.ps1) is now archived **without edits** in [`scripts/historical/`](scripts/historical/README.md). It reads an **existing 28-record CSV**; the directory's **30 final user accounts** were verified separately, and earlier screenshots show separate IT (`amorgan`) and Finance (`sjohnson`) account creation consistent with the other two accounts; a complete account-by-account reconciliation remains pending. The original [28-record `employees.csv`](scripts/historical/employees.csv) is archived alongside the script; the CSV and script are historical source inputs, not proof of a fresh run. The other scripts below are new reference implementations and helpers, not replacements presented as the original.

| New source | Purpose | State |
|---|---|---|
| [Archived Create-Employees-v3.ps1](scripts/historical/Create-Employees-v3.ps1) | User-supplied copy of historical 28-row onboarding logic; account/group checks and random initial password generation | **Source preserved; not re-executed** |
| [Invoke-LabEmployeeProvisioning.ps1](scripts/Invoke-LabEmployeeProvisioning.ps1) and [CSV validator](scripts/EmployeeCsv.Validation.psm1) | Strict CSV input validation, per-department OU/group preflight, rerunnable planning, disabled-user creation only with explicit -Apply | **CSV validation passed offline CI; AD write path not executed** |
| [Verify-Lab.ps1](scripts/Verify-Lab.ps1) | Read-only checks for users, group counts, DHCP, DNS, SMB and temporary-object cleanup; incomplete sections fail | **Source parsed in CI; live DC01 checks not executed** |
| [Analyze-AuthenticationEvents.ps1](scripts/Analyze-AuthenticationEvents.ps1) | Reads local events 4771 and 4740 or a synthetic CSV; flags repeated bad-password activity with nearby lockout | **Synthetic positive/negative scenarios passed CI; not deployed** |
| [Export-SecurityEvents.ps1](scripts/Export-SecurityEvents.ps1) | Read-only local event query; optional on-disk CSV | **New; not runtime-verified** |
| [Offline tests and synthetic fixtures](tests/) | CSV validation and example authentication correlation without AD access | **Passed on GitHub Actions, [see run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43669522297)** |

**Automated offline verification:** A [GitHub Actions run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43669522297) parsed the PowerShell source/test files available at that commit and passed synthetic CSV validation, positive/negative authentication scenarios, and checks for 455 local links, 107 screenshots, and the architecture SVG. These results do **not** establish that AD-writing code or Windows Security-log queries run successfully against DC01.

Start with [script usage and safety instructions](scripts/README.md). The separate new onboarding example is **plan-only by default** and, even with -Apply, creates disabled accounts without passwords. Do not confuse these reference files with tested production automation.

## Known limits and unresolved checks

- **DNS:** Creating a reverse zone and PTR fixed the missing PTR/server-name lookup, but intermittent timeout messages with ordinary non-trailing-dot nslookup were not conclusively explained. See [precise observation and hypotheses](documentation/07-dhcp-and-dns-troubleshooting.md#root-cause-and-unresolved-condition).
- **USB restriction:** GPO application and Deny_Write=1 were verified. **A physical/virtual removable-disk write-denial experiment was not performed.**
- **Inactivity lock:** The 600-second policy was observed in configuration and a Windows lock screen was captured. The evidence does **not independently measure** the idle period to confirm that exact timing caused the lock.
- **SMB access:** Positive/negative tests used two named fictional users, not all 30; the four-department effective-access matrix is not complete.
- **Event analysis:** 4771/4740/4767 records were queried manually. New analysis code has not been run against the VM's actual Security log and is not a SIEM alert rule.
- **Design:** One domain controller, one client, no production identities, no failover, no tested restoration, and no separate file server.

Read the [full test matrix and remaining work](documentation/10-verification-and-limitations.md). These limits are included so a reviewer can distinguish what was **observed**, what was **configured only**, and what is **still to be tested**.

---

*Independent educational lab; results are linked to original numbered screenshots. Scripts added after the lab are identified as new work and are not presented as historical evidence.*
