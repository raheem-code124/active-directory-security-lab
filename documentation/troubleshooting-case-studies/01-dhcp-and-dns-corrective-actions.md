# Troubleshooting case 01 — DHCP and DNS service validation

**Environment:** `DC01` Windows Server 2025 evaluation, `CLIENT01` Windows 11 Enterprise evaluation, VirtualBox `CORP-LAB`, `192.168.50.0/24`.  
**Status:** DHCP and forward/PTR lookups verified; intermittent plain-`nslookup` timeouts remain an open diagnostic observation.

## Incident at a glance

| Question | Finding |
|---|---|
| What was needed? | Replace manually maintained client IPv4 settings with centrally distributed DHCP/DNS settings |
| What worked? | Authorized server, active scope, lease assignment, ping, AD DNS A lookup and reverse PTR lookup |
| What failed? | Initially no reverse PTR for DC01; ordinary `nslookup` also displayed timeouts |
| What was corrected? | Created AD-integrated reverse zone and DC01 PTR |
| What remains unproven? | Why non-trailing-dot `nslookup` sometimes timed out, despite correct DNS A results |

## Diagnostic timeline

1. **Establish infrastructure:** Installed DHCP role; AD-authorized `DC01.corp.example.test` at `192.168.50.10` ([59–60](../evidence-index.md)).
2. **Create scope/options:** `192.168.50.100–.200`, mask `255.255.255.0`, DNS server `.10`, suffix `corp.example.test` ([61–62](../evidence-index.md)).
3. **Validate client:** `ipconfig /all` showed `.100`, correct DHCP and DNS server; ping to `.10` passed ([63–64](../evidence-index.md)).
4. **Isolate name resolution:** IP reachability worked, but PTR resolution failed and ordinary `nslookup` timed out before returning a correct A record ([65](../../screenshots/65-dns-forward-and-reverse-lookup-diagnostics.png)).
5. **Check server's reverse zones:** Network-specific reverse zone wasn't present ([66](../../screenshots/66-dns-reverse-zone-diagnostic.png)).
6. **Correct the missing PTR:** Add `50.168.192.in-addr.arpa`, record `10 → DC01.corp.example.test` ([67](../../screenshots/67-dns-reverse-zone-and-ptr-created.png)).
7. **Re-test:** Explicit A and PTR commands worked; full-FQDN `nslookup` with terminal dot worked without timeouts ([68](../../screenshots/68-dns-repair-verification.png), [69](../../screenshots/69-dns-query-timeout-isolation.png), [70](../../screenshots/70-dns-final-query-verification.png)).

## Evidence-based technical interpretation

The reverse record allowed a **reverse lookup of the DNS server's own IP**, changing `nslookup` server display from `UnKnown` to `DC01.corp.example.test`. It did **not** itself prove that all forward-query timeout behavior was fixed.

The literal terminal dot in `DC01.corp.example.test.` instructs the resolver to treat the name as fully qualified. The difference in behavior suggests additional query processing should be investigated; capturing DNS packets or enabling analytic DNS logging would be reasonable **future work**, not a completed lab action.

## Lessons / repeatable checklist

- Verify link/IP/DHCP separately from name resolution and account credentials.
- Query the intended DNS server explicitly when isolating name-resolution problems.
- Separate forward A records from reverse PTR records.
- Keep a known-issue note if a diagnostic symptom persists after one correction.
- Never place the lab DHCP service on an unisolated physical network.

[Full Phase 7 walkthrough](../07-dhcp-and-dns-troubleshooting.md).
