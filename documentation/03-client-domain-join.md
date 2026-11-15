# Phase 3 — Deploy, network, and domain-join CLIENT01

[← Phase 2](02-active-directory-structure-and-automation.md) · [Documentation index](README.md) · [Next: Provisioning →](04-bulk-provisioning-and-validation.md)

## Goal

Bring a Windows 11 workstation into the domain so centrally created users can authenticate and receive Windows policies. A successful domain join depends on name resolution, basic network reachability, and suitable time configuration.

### VM and operating system

- Hypervisor: Oracle VirtualBox.
- Workstation VM: `AD-LAB-CLIENT01`, hostname `CLIENT01`.
- OS: Windows 11 Enterprise evaluation.
- Network: isolated `CORP-LAB` IPv4 `192.168.50.0/24`.
- Initially configured static IPv4 `192.168.50.20` and domain DNS `192.168.50.10`, before DHCP was introduced in Phase 7.
- Joined domain: `corp.example.test` (`CORP`).

## Implementation and evidence

| Capture | Technical activity |
|---|---|
| [23](../screenshots/0023-windows-11-enterprise-iso-downloaded.png) | Downloaded Windows 11 Enterprise evaluation ISO |
| [24](../screenshots/0024-windows-11-client-vm-created.png) | Created the CLIENT01 virtual machine |
| [25](../screenshots/0025-windows-11-initial-setup.png) | Completed OS setup |
| [26](../screenshots/0026-windows-11-client-desktop.png) | Verified a usable Windows desktop |
| [27](../screenshots/0027-windows-11-license-verification.png) | Checked the evaluation/license state |
| [28](../screenshots/0028-client-isolated-network-configured.png) | Configured the isolated VM network |
| [29](../screenshots/0029-client01-computer-renamed.png) | Renamed the workstation |
| [30](../screenshots/0030-client01-static-ip-configuration.png) | Assigned IPv4 and DC01 as the DNS server |
| [31](../screenshots/0031-client-domain-controller-connectivity.png) | Verified network reachability to DC01 |
| [32](../screenshots/0032-active-directory-dns-discovery.png) | Checked discovery of the AD DNS namespace |
| [33](../screenshots/0033-client01-time-synchronization.png) | Checked/synchronized client clock |
| [34](../screenshots/0034-client01-domain-join-success.png) | Joined the machine to `corp.example.test` |
| [35](../screenshots/0035-domain-employee-login-verification.png) | Signed in with a domain employee account |
| [36](../screenshots/0036-domain-services-health-check.png) | Rechecked domain-service health |

## Diagnostics used

```cmd
hostname
ipconfig /all
ping 192.168.50.10
nslookup DC01.corp.example.test 192.168.50.10
whoami
```

**Interpretation**

1. A ping reply from `192.168.50.10` confirms IP reachability, **not** necessarily healthy AD DS or DNS.
2. A DNS query for `DC01.corp.example.test` confirms the expected domain controller record is reachable.
3. Clock checking matters because Kerberos uses time-sensitive credentials.
4. A completed domain join and a successful `CORP\<employee>` session demonstrate end-to-end connectivity beyond a simple ping.
5. Active Directory Users and Computers later showed `CLIENT01` under `Company/Workstations`, allowing machine-specific security GPOs.

## Observed outcomes

- CLIENT01 was joined to the domain and usable with a domain identity.
- `whoami` displayed domain-form account names such as `corp\amorgan` and `corp\sjohnson` during later access tests.
- Authentication and GPO application were shown through separate screenshots in subsequent phases.
- The OS remained an evaluation copy; production licensing was not claimed.

## Troubleshooting considerations

If the workstation can't join, check (in this order): virtual NIC network name, IP/subnet, DNS pointed at DC01, `ping` reachability, DNS SRV/domain discovery, client time, and the entered domain/user. Avoid bypassing DNS with an external public resolver; a domain member should query its domain DNS server for AD records.

**Limitations:** Only one workstation joined. No deployment imaging, fleet management, endpoint detection agent, or Windows Autopilot was implemented.
