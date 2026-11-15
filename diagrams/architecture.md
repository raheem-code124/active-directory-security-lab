# Network and security architecture

[← Main README](../README.md) · [Configuration reference](../documentation/configuration-reference.md) · [Open SVG diagram](architecture.svg)

![Enterprise AD security lab architecture](architecture.svg)

## Editable Mermaid diagram

```mermaid
flowchart TB
  H["Windows host computer<br/>Oracle VirtualBox"]
  subgraph NET["Isolated CORP-LAB virtual network — 192.168.50.0/24"]
    DC["DC01 — Windows Server 2025 Evaluation<br/>192.168.50.10 static<br/>Active Directory • DNS • DHCP • SMB • GPO • Security logs"]
    PC["CLIENT01 — Windows 11 Enterprise Evaluation<br/>192.168.50.100 DHCP<br/>DNS: 192.168.50.10<br/>Domain-joined workstation"]
    DC <-->|"DNS / Kerberos / LDAP / SMB / DHCP / Group Policy"| PC
  end
  H --> NET
  DC --> OU["AD: corp.example.test<br/>Company OUs / 30 users / 4 security groups"]
  DC --> GPO["Workstation GPOs: 600s lock / Firewall / USB write restriction<br/>DC GPO: account, group, Kerberos auditing"]
  DC --> SH["SMB shares: Finance / HR / IT / Operations<br/>NTFS Modify + SMB Change by department"]
  DC --> EV["Windows Security event log<br/>4720 4726 4728 4730 4771 4740 4767"]
```

## Explanation

1. **VirtualBox host:** Runs two lab virtual machines. The `CORP-LAB` virtual network keeps the Windows DHCP and domain services away from the physical/home network.
2. **DC01:** Central server. Holds the single domain's directory accounts, publishes DNS, leases IPv4 addresses, stores four departmental SMB shares, and records domain security events.
3. **CLIENT01:** Joined to `corp.example.test`. Employee accounts authenticate to the domain, receive machine GPOs, and access authorized departmental file shares.
4. **RBAC:** Security groups are the bridge between department membership and shared-folder permissions. Users do not receive broad access to all departmental folders.
5. **Incident response:** Failed authentication originates at CLIENT01 and is observable in DC01's security log. A test fine-grained password policy was created and removed after the account-lockout exercise.

### Boundary and scope

This is an educational two-VM layout. There is **no** production firewall appliance, gateway, internet routing configuration, redundant DC, SIEM, or external identity provider. The diagram deliberately omits those items. The demonstrated client IP is the DHCP-assigned `192.168.50.100`; an earlier static client address was used during setup.

### Ports and protocols (conceptual, not a packet capture)

- DNS typically uses UDP/TCP 53.
- Kerberos authentication commonly uses UDP/TCP 88.
- LDAP/Active Directory traffic commonly uses TCP/UDP 389.
- SMB file access normally uses TCP 445.
- DHCP IPv4 uses UDP 67/68.

These are protocol reference values, **not** a claim that every port was individually tested or packet-captured.


## Security architecture review — intentionally simplified

**Observed training design:** DC01 simultaneously acted as an AD DS domain controller, DNS/DHCP server, and SMB file host on the same isolated network. This lowered VM/resource requirements and allowed directory identity and access-control exercises with two VMs. It is not recommended as a production privileged-identity design.

**Production-style alternative (not deployed):** Use at least one dedicated domain member server for SMB file services, isolate administrative access to domain controllers, restrict SMB reachability to clients that need it, and design redundant DC/DNS services appropriate to an organization's recovery needs. Control Tier 0 administrative credentials separately from regular workstation and file-server accounts.

**Trust boundary:** A compromised SMB workload co-located with the DC would create a much more serious privilege-exposure problem than the same workload on a separate member server. The lab's two-VM architecture therefore demonstrates functionality, **not** a hardened enterprise segmentation model.

**Evidence limit:** The diagram is an architecture illustration derived from the captured configuration. It is not a packet capture, port scan, AD topology export, or independent security assessment.
