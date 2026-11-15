# Phase 1 — Build and validate the domain controller

[← Documentation index](README.md) · [Next: Directory design →](02-active-directory-structure-and-automation.md)

## Objective

Create a repeatable, **isolated** Windows Server environment that can centrally manage domain identities, DNS name resolution, and future domain-joined workstations. The main deliverable was a functioning DC01 for `corp.example.test`, with network and service health recorded before any endpoint or security exercises.

## Environment and planning

| Component | Lab configuration |
|---|---|
| Host | Personal Windows PC with Oracle VirtualBox |
| Server VM | `AD-LAB-DC01`, Windows Server 2025 evaluation |
| Domain controller computer name | `DC01` |
| Domain | `corp.example.test` |
| NetBIOS domain | `CORP` |
| Static IPv4 | `192.168.50.10/24` |
| Internal network | Isolated `CORP-LAB` (`192.168.50.0/24`) |
| Roles | Active Directory Domain Services (AD DS) and DNS Server |
| Expected clients | Windows 11 evaluation, to be domain-joined later |

### Step-by-step build record

**01–04 — Installation and virtual machine**

1. Obtained the Windows Server installation ISO and documented the download.
2. Created the Windows Server VM in VirtualBox and selected the server edition.
3. Installed Windows Server, booted to the desktop, and captured a working server baseline.
4. Kept all domain/DHCP experiments on the isolated virtual network; the Windows computer's real network was not the test target.

Evidence: [01 ISO](../screenshots/0001-windows-server-iso-downloaded.png) · [02 VM](../screenshots/0002-server-vm-created.png) · [03 edition](../screenshots/0003-windows-server-edition.png) · [04 desktop](../screenshots/0004-windows-server-desktop.png).

**05–06 — Hostname and TCP/IP**

5. Renamed the server to `DC01` and used a static IP (`192.168.50.10`), so clients could consistently use it for domain DNS.
6. Verified the configured IPv4 network before promoting the machine.

Evidence: [05 rename](../screenshots/0005-server-renamed-dc01.png) · [06 static IP](../screenshots/0006-server-static-ip-configuration.png).

**07–09 — Install AD DS and promote**

7. Installed the AD DS server role.
8. Ran and passed Active Directory domain-service prerequisite checks.
9. Promoted the server to the first domain controller of `corp.example.test`, with DNS integration.

Evidence: [07 AD role](../screenshots/0007-active-directory-role-installed.png) · [08 prerequisites](../screenshots/0008-domain-prerequisites-passed.png) · [09 promotion](../screenshots/0009-domain-controller-promoted.png).

**10–12 — Post-install health, clock, and baseline**

10. Checked the directory identity: `DNSRoot = corp.example.test` and `NetBIOSName = CORP`.
11. Verified that both the `NTDS` (Active Directory Domain Services) and `DNS` services were running.
12. Inspected the initial server time and corrected its clock before continuing with Kerberos-based domain authentication. Time consistency matters for Kerberos.
13. Captured an initial VirtualBox working baseline/snapshot.

Evidence: [10a domain](../screenshots/0010a-domain-identity-verification.png) · [10b services](../screenshots/0010b-active-directory-services.png) · [10c DNS](../screenshots/0010c-domain-dns-verification.png) · [11a time](../screenshots/0011a-server-time-verification.png) · [11b snapshot](../screenshots/0011b-domain-controller-baseline-snapshot.png) · [12 time fix](../screenshots/0012-server-clock-corrected.png).

## Commands and why they matter

The following are **safe, read-only checks** for reproducing the observed validation on DC01:

```powershell
Get-ADDomain | Select-Object DNSRoot,NetBIOSName
Get-Service NTDS,DNS
hostname
ipconfig /all
w32tm /query /status
```

| Check | Intended behavior | Observed outcome |
|---|---|---|
| Domain identity | Correct FQDN and short name | `corp.example.test`, `CORP` |
| NTDS service | Running | Running |
| DNS service | Running | Running |
| Domain controller address | Stable IP | `192.168.50.10` |
| Time configuration | Suitable for domain authentication | Time was inspected and corrected |

## Why this stage matters

A domain controller is the base of centralized identity and workstation administration. Incorrect DNS, bad time synchronization, or an unstable DC address can break domain joins, user authentication, policy distribution, and file access. This phase deliberately validated those prerequisites before adding complexity.

**Limitations:** Only one domain controller was built. Replication, high availability, backup/restore testing, and production hardening were not part of this lab. The server uses an evaluation OS.
