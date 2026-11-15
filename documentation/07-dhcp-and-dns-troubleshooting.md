# Phase 7 — DHCP delivery, DNS repair, and network diagnostics

[← Phase 6](06-department-file-shares-and-access-control.md) · [Documentation index](README.md) · [Next: Auditing →](08-security-auditing-and-event-validation.md)

## Objective

Move CLIENT01 from manually assigned IPv4 configuration to centrally managed DHCP, preserve access to `DC01` and the domain, and investigate DNS timeouts without making an unsupported claim of complete resolution.

## DHCP server implementation

**DC01** was configured as the DHCP server, authorized in Active Directory at `192.168.50.10`.

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName "DC01.corp.example.test" -IPAddress 192.168.50.10
Get-DhcpServerInDC
```

Actual result: role installation succeeded; domain authorization returned the expected server IP and FQDN.

Evidence: [59 role](../screenshots/59-dhcp-server-role-installed.png) · [60 authorization](../screenshots/60-dhcp-server-active-directory-authorization.png).

### Scope and options

Created and activated the following scope on an isolated virtual network:

```powershell
Add-DhcpServerv4Scope -Name "CORP-LAB Clients" `
  -StartRange 192.168.50.100 -EndRange 192.168.50.200 `
  -SubnetMask 255.255.255.0 -State Active

Get-DhcpServerv4Scope

Set-DhcpServerv4OptionValue -ScopeId 192.168.50.0 `
  -DnsServer 192.168.50.10 -DnsDomain "corp.example.test"

Get-DhcpServerv4OptionValue -ScopeId 192.168.50.0
```

| Parameter | Verified value |
|---|---|
| Scope ID | `192.168.50.0` |
| Subnet mask | `255.255.255.0` |
| Start | `192.168.50.100` |
| End | `192.168.50.200` |
| State | Active |
| DNS server | `192.168.50.10` |
| DNS domain | `corp.example.test` |
| Scope lease time | Eight days observed |
| Default router | Not configured in captured options |

Evidence: [61 scope](../screenshots/61-dhcp-address-scope-created.png) · [62 options](../screenshots/62-dhcp-dns-options-configured.png).

**Why DHCP?** Each computer needs a **unique** address on the subnet. DHCP supplies those addresses automatically and consistently, together with correct DNS settings. It doesn't give every employee the same IP address.

### Client verification

CLIENT01 was switched to automatic addressing; `ipconfig /all` showed:

- IPv4 `192.168.50.100`, mask `255.255.255.0`
- DHCP Server `192.168.50.10`
- DNS Servers `192.168.50.10`
- Domain/DNS suffix `corp.example.test`

The client successfully pinged `192.168.50.10` (4 sent, 4 replies, 0% lost). Domain share access was rechecked. One earlier attempt returned **“The user name or password is incorrect”**; an explicit `CORP\sjohnson` session subsequently accessed the Finance share successfully. Network connectivity and a user's authentication credentials are separate failure domains.

Evidence: [63 lease](../screenshots/63-client-dhcp-address-assignment.png) · [64a connectivity/authentication error](../screenshots/64a-dhcp-connectivity-and-authentication-error.png) · [64b working domain share](../screenshots/64b-domain-share-access-after-dhcp.png).

## DNS troubleshooting timeline

### Symptom

The client could reach the DNS server by IP and obtain the DC's correct IPv4 address, but ordinary `nslookup DC01.corp.example.test` emitted repeated **DNS request timed out** messages before printing the result. Initially, `nslookup` also presented the DNS server as `UnKnown`.

### Investigation

1. Compared `ping`, `nslookup`, and explicit `Resolve-DnsName` A/PTR responses on CLIENT01.
2. A records resolved `DC01.corp.example.test` to `192.168.50.10`.
3. PTR queries for `192.168.50.10` initially failed; DC01 did not have an appropriate `50.168.192.in-addr.arpa` reverse lookup zone.
4. Inspected existing reverse zones on DC01; only generic `0.in-addr.arpa`, `127.in-addr.arpa`, `255.in-addr.arpa` were present.
5. Created an AD-integrated reverse zone and a PTR record.

Relevant DC01 commands executed:

```powershell
Get-DnsServerZone |
  Where-Object IsReverseLookupZone |
  Select-Object ZoneName,IsDsIntegrated

Add-DnsServerPrimaryZone -NetworkId "192.168.50.0/24" `
  -ReplicationScope Domain -DynamicUpdate Secure -PassThru

Add-DnsServerResourceRecordPtr -Name "10" `
  -ZoneName "50.168.192.in-addr.arpa" `
  -PtrDomainName "DC01.corp.example.test"

Get-DnsServerResourceRecord -ZoneName "50.168.192.in-addr.arpa" -RRType PTR
```

The query returned PTR `10 → DC01.corp.example.test.`. Evidence: [65 diagnostics](../screenshots/65-dns-forward-and-reverse-lookup-diagnostics.png) · [66 zone inventory](../screenshots/66-dns-reverse-zone-diagnostic.png) · [67 zone + PTR](../screenshots/67-dns-reverse-zone-and-ptr-created.png).

### Re-test after the change

On CLIENT01:

```powershell
Resolve-DnsName -Name 192.168.50.10 -Server 192.168.50.10 -Type PTR -DnsOnly
Resolve-DnsName -Name DC01.corp.example.test -Server 192.168.50.10 -Type A -DnsOnly
nslookup -type=A DC01.corp.example.test. 192.168.50.10
nslookup -type=AAAA DC01.corp.example.test. 192.168.50.10
nslookup DC01.corp.example.test. 192.168.50.10
```

| Test | Observed |
|---|---|
| Explicit PTR query | `192.168.50.10 → DC01.corp.example.test` |
| Explicit A query | `DC01.corp.example.test → 192.168.50.10` |
| `nslookup` DNS server name | Changed from `UnKnown` to `DC01.corp.example.test` |
| `-type=A` query with trailing dot | Correct A response, no timeout |
| `-type=AAAA` with trailing dot | No AAAA address returned; no timeout |
| Fully qualified `nslookup` with final dot | Correct A response, no timeout |
| Unqualified ordinary `nslookup DC01.corp.example.test` | Correct final A response **but intermittent timeouts persisted** |

Evidence: [68 reverse test](../screenshots/68-dns-repair-verification.png) · [69 A/AAAA isolation](../screenshots/69-dns-query-timeout-isolation.png) · [70 FQDN test](../screenshots/70-dns-final-query-verification.png).

### Root cause and unresolved condition

**Confirmed:** The initial missing reverse zone/PTR explained why the DNS server name was `UnKnown` and why PTR lookup failed. Creating the reverse zone and PTR fixed that specific problem.

**Not confirmed:** The root cause of timeout warnings on the no-trailing-dot `nslookup` invocation. Differences in the exact queried name / search suffix behavior were a diagnostic hypothesis, **not a proven final root cause**. It would be inaccurate to claim all DNS failures were fully remediated.

## Final phase outcome

DHCP authorization and scope work, a lease was issued to CLIENT01, the domain DNS address was supplied, ping and authorized share access were observed, and forward/reverse name lookups were demonstrated. A remaining `nslookup` behavior is documented as a known issue for future packet-level diagnostics.

**Isolation note:** Running DHCP on a real unisolated LAN can disrupt other computers. These settings were intended only for the dedicated VirtualBox lab network.

[See standalone diagnostic case](troubleshooting-case-studies/01-dhcp-and-dns-corrective-actions.md).
