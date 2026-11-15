# Follow-up 12 — Client DNS timeouts and packet evidence

[Original DHCP/DNS troubleshooting](07-dhcp-and-dns-troubleshooting.md) · [Evidence index](evidence-index.md)

## Reported symptom

CLIENT01 received IPv4 `192.168.50.100/24`, DHCP and DNS server `192.168.50.10`, and domain suffix `corp.example.test`. After the earlier PTR repair, queries for `DC01.corp.example.test` returned the correct local A record `192.168.50.10`, but some forms of `nslookup` still displayed intermittent two-second timeout warnings.

Evidence: [CLIENT01 configuration](../screenshots/0107-client01-network-configuration.png) · [Lookup comparison](../screenshots/0108-client01-dns-lookup-comparison.png) · [A/AAAA comparison](../screenshots/0109-dns-a-aaaa-query-isolation.png).

## Suffix and query-debug tests

Using `nslookup -debug` showed a correct PTR response for `192.168.50.10` and correct A answers for the DC. One ordinary query also generated the expanded question `DC01.corp.example.test.corp.example.test` and an `NXDOMAIN` response. Explicit trailing-dot and `-nosearch` tests avoided that suffix expansion and produced correct A results.

The client configuration reported `UseSuffixSearchList=True`, `SuffixSearchList={corp.example.test}`, `UseDevolution=True` and `DevolutionLevel=0`.

Evidence: [Debug comparison](../screenshots/0110a-dns-debug-query-comparison.png) · [Suffix trace 1](../screenshots/0110b-dns-suffix-debug-part1.png) · [Suffix trace 2](../screenshots/0110c-dns-suffix-debug-part2.png) · [No-search comparison](../screenshots/0111-dns-suffix-search-disabled.png) · [DNS client settings](../screenshots/0118-client01-dns-suffix-settings.png).

**Inference, not established root cause:** Suffix expansion explains an additional erroneous lookup, but the captured evidence does not prove it caused every timeout or show a complete permanent remediation.

## DNS packet capture

On CLIENT01, Packet Monitor was configured with an address/port filter for the domain DNS service at `192.168.50.10:53`. Collection was started before repeating DNS queries. The resulting `C:\DNS-Capture\114-dns-capture.etl` was converted to `116-dns-analysis.pcapng`. The output showed **148 packets processed/formatted and 0 packets dropped**.

Evidence: [PktMon available](../screenshots/0112-packet-monitor-availability.png) · [DNS filter](../screenshots/0113-dns-packet-capture-filter.png) · [Capture start](../screenshots/0114a-dns-packet-capture-started.png) · [Capture status](../screenshots/0114b-dns-packet-capture-status.png) · [Queries during capture](../screenshots/0115-dns-timeout-during-packet-capture.png) · [ETL and PCAPNG saved](../screenshots/0116-dns-packet-capture-saved.png).

The screenshots confirm artifact creation and packet counts. **They do not document a full frame-by-frame PCAP analysis.**

## DC01 DNS server and routing checks

| Item | Observed |
|---|---|
| Recursive DNS enabled | True |
| Recursion timeout | 8 |
| Additional timeout | 4 |
| Retry interval | 3 |
| Explicit forwarder IP addresses | None listed |
| Root hints | Present; 13 root server names shown |
| Use root hints | True |
| DC01 address | `192.168.50.10` |
| IPv4 default gateway | Not set |
| Default IPv4 route | None returned for `0.0.0.0/0` |

Evidence: [DNS recursion and forwarders](../screenshots/0119-dc01-dns-recursion-and-forwarders.png) · [Root hints](../screenshots/0120-dc01-dns-root-hints-verification.png) · [IPv4 routes](../screenshots/0121-dc01-external-network-route-verification.png) · [Timing comparison](../screenshots/0122-dns-recursion-timing-comparison.png) · [Saved investigation transcript](../screenshots/0123-dns-investigation-summary.png).

Because the lab uses an internal network, a missing default route limits access beyond that subnet. That configuration **does not prove** the root cause of intermittent warnings for local authoritative queries.

## Outcome

**Confirmed:** Local A/PTR resolutions work, suffix-expanded queries occurred, DNS traffic was captured and exported, and server recursion/route configuration was inspected. **Unresolved:** The precise DNS request/retry responsible for the intermittent warning; a fully verified lasting fix. This case remains an **investigation**, not a claim of complete DNS timeout remediation.
