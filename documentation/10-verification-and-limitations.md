# Final verification matrix and limitations

[Project overview](../README.md) · [Documentation hub](README.md) · [All screenshots](evidence-index.md)

**Assessment date: November 15, 2026.** The project has two distinct directory states: the **original CORP lab (30 accounts)** and an **isolated clone (34 accounts only after adding four disabled test accounts)**. Do not combine these counts.

## Observed control outcomes

| Control or workflow | Verified result | Evidence |
|---|---|---|
| Original AD account baseline | 30 fictional employee accounts; department group counts IT 8, HR 7, Finance 8, Operations 7 | [User count](../screenshots/0092-active-directory-30-user-verification.png) · [Groups](../screenshots/0093-active-directory-security-group-verification.png) |
| Read-only DC01 verification | 21 completed comparisons, 0 mismatches, 0 sections errored; limited to tool's listed checks | [Checks](../screenshots/0101-live-active-directory-verification.png) · [Saved output](../screenshots/0102-live-verification-output-saved.png) |
| Historical roster reconciliation | 28 archived CSV records + `amorgan` (IT) and `sjohnson` (Finance) = 30 matched live identities | [Live reconciliation](../screenshots/0105-live-account-reconciliation.png) · [Transcript](../screenshots/0106-account-reconciliation-evidence-saved.png) |
| CLIENT01 domain join/login | Domain join and employee domain sign-in demonstrated | [Join](../screenshots/0034-client01-domain-join-success.png) · [Sign-in](../screenshots/0035-domain-employee-login-verification.png) |
| Workstation inactivity | 600-second lock setting configured and lock screen captured; time interval not measured independently | [Policy state](../screenshots/0043-workstation-gpo-application-verification.png) · [Lock screen](../screenshots/0044-workstation-auto-lock-test.png) |
| Windows firewall | GPO applied; Domain, Private, Public enabled with inbound Block/outbound Allow defaults | [GPO](../screenshots/0047a-workstation-gpo-verification.png) · [Profiles](../screenshots/0047b-workstation-firewall-verification.png) |
| Removable-storage policy | GPO applied on CLIENT01 and `Deny_Write=0x1` read from registry | [GPO applied](../screenshots/0131a-usb-restriction-gpo-applied.png) · [Registry](../screenshots/0131b-usb-write-restriction-registry-verified.png) |
| Actual USB write block | **Not tested**, no physical or virtual removable-media write attempted | [Limitations](05-workstation-group-policy-security.md) |
| DHCP | Scope `192.168.50.100–200` active; CLIENT01 lease `192.168.50.100` and DC01 DNS supplied | [Scope](../screenshots/0061-dhcp-address-scope-created.png) · [Lease](../screenshots/0063-client-dhcp-address-assignment.png) |
| DNS A/PTR | Local name to IP and server IP to PTR resolved; intermittent `nslookup` warnings still under investigation | [PTR repair](../screenshots/0068-dns-repair-verification.png) · [A/AAAA](../screenshots/0109-dns-a-aaaa-query-isolation.png) |
| DNS follow-up | Suffix-added `NXDOMAIN` question; 148 packets formatted, 0 drops; capture exported, not conclusively decoded | [Debug trace](../screenshots/0110b-dns-suffix-debug-part1.png) · [PCAPNG](../screenshots/0116-dns-packet-capture-saved.png) |
| SMB/NTFS design | Four department-specific ACLs; dept SMB Change and NTFS Modify | [Share ACLs](../screenshots/0124-dc01-smb-share-acl-verification.png) · [NTFS ACLs](../screenshots/0125-dc01-ntfs-folder-permissions.png) |
| User-token SMB directory checks | 16 total across four accounts and four shares: 4 authorized allowed, 12 unauthorized denied | [IT](../screenshots/0127a-it-employee-share-access-test.png) · [HR](../screenshots/0128d-hr-employee-share-access-test.png) · [Finance](../screenshots/0129a-finance-employee-share-access-test.png) · [Operations](../screenshots/0130a-operations-employee-share-access-test.png) |
| User-token SMB file operations | Four authorized create/read passes; four cross-department denied writes and test-file cleanup | [IT cleanup](../screenshots/0127d-it-test-file-cleanup.png) · [HR cleanup](../screenshots/0128f-hr-unauthorized-write-and-cleanup.png) · [Finance cleanup](../screenshots/0129c-finance-unauthorized-write-denied-and-cleanup.png) · [Operations cleanup](../screenshots/0130c-operations-unauthorized-write-and-cleanup.png) |
| Simulated help-desk ticket | HR user `mpatel` password reset, login restored and HR effective access confirmed | [Reset](../screenshots/0128b-hr-password-reset-confirmation.png) · [Login](../screenshots/0128c-hr-password-reset-login-verification.png) |
| User/group lifecycle and authentication auditing | Controlled Security Events 4720, 4726, 4728, 4730, 4771, 4740, 4767 observed | [Creation](../screenshots/0074b-security-event-4720-details.png) · [Kerberos](../screenshots/0080a-kerberos-failed-authentication-event.png) · [Lockout](../screenshots/0085-account-lockout-event-4740-investigation.png) · [Unlock](../screenshots/0086-account-unlock-and-security-event-verification.png) |
| Provisioning plan and WhatIf | Four planned disabled creations; no change at 30 clone users | [Plan](../screenshots/0132f-provisioning-read-only-plan-test.png) · [WhatIf](../screenshots/0132g-provisioning-whatif-safety-test.png) |
| Controlled provisioning Apply | Four disabled demo accounts created on disconnected clone; user count 30→34 | [Apply](../screenshots/0132h-isolated-clone-provisioning-execution.png) |
| Group/disabled and rerun verification | Four new accounts have `Disabled=True` and correct group memberships; plan-only rerun shows four `ALREADY_CORRECT` | [Final validation](../screenshots/0132i-provisioning-final-verification.png) |

## Findings that must not be overstated

1. **Training scale.** The baseline is one DC01/one CLIENT01. No second production DC, replication, true failover, backup/restore, production clients or real enterprise incident was deployed.
2. **Client DNS timeouts.** The PTR fix, suffix-expanded queries, packet export, lack of outbound default route and successful local A responses narrow the investigation but do **not** conclusively identify every timeout's cause or prove full remediation.
3. **USB.** Group Policy/registry configuration was verified, not an actual failed write to removable media.
4. **Access-testing sample.** Four representative domain users exercised all 16 share directory combinations. No full 30-account effective-entitlement test was completed. Cross-department write denial tested one other share per user.
5. **GPO idle behavior.** The configured 600-second inactivity value and captured locked workstation are not a measured 600-second timing test.
6. **Historical source integrity.** The archived 2,599-byte PowerShell script and 778-byte CSV have SHA-256 hashes matching the values captured in DC01 screenshot 0097. This establishes file identity at capture time, not proof of authorship or successful historical execution.
7. **Provisioning safety paths.** The real AD clone test covers plan, WhatIf, successful disabled creates, group placement and plan-only rerun; negative error/failure paths were mocked offline but **not reproduced end-to-end on a real DC**.
8. **Monitoring limitations.** Security event interpretation was manual. The new authentication analyzer has synthetic CI tests; no deployed SIEM, EDR, alerting pipeline or real-log analyzer output is claimed.
9. **Privacy.** The repository remains **private** until every screenshot and archived artifact receives a manual content review for credentials or identifying data. Link integrity alone is insufficient.

## Provenance

The historical [`Create-Employees-v3.ps1`](../scripts/historical/Create-Employees-v3.ps1) and [28-row original CSV](../scripts/historical/employees.csv) are archived unchanged as supplied. The newer [plan-first provisioning implementation](../scripts/Invoke-LabEmployeeProvisioning.ps1) is a distinct post-lab artifact. The original 30-user roster was verified live; the four **additional** accounts were created only on a disconnected, duplicate DC01 identity test VM attached to `CORP-LAB-TEST`. The clone must never be reattached to the original `CORP-LAB` network.

For full context read [live roster verification](11-live-roster-and-integrity-verification.md), [DNS follow-up](12-dns-follow-up-investigation.md), [department access](13-department-access-control-follow-up.md), and [clone provisioning](14-isolated-provisioning-validation.md).
