# Technical documentation and evidence guide

This is the technical record for the fictional **CORP** enterprise lab. Read [the main README](../README.md) for a recruiter-friendly overview, then use the phase reports below to inspect exact commands, results, corrective actions, and limitations.

## Chronological walkthrough

| Phase | Report | Key result | Primary evidence |
|---|---|---|---|
| 1 | [Domain controller and network](01-environment-and-domain-controller.md) | DC01, AD DS, DNS, static 192.168.50.10 | [01–12](evidence-index.md#phase-1--server-foundation-0112) |
| 2 | [AD structure and initial automation](02-active-directory-structure-and-automation.md) | OUs, groups, onboarding scripts and corrections | [13–22](evidence-index.md#phase-2--directory-and-initial-automation-1322) |
| 3 | [Client and domain join](03-client-domain-join.md) | CLIENT01 joined `corp.example.test` | [23–36](evidence-index.md#phase-3--client-deployment-2336) |
| 4 | [Bulk onboarding validation](04-bulk-provisioning-and-validation.md) | 30 accounts; 8/7/8/7 department group members | [37–41](evidence-index.md#phase-4--bulk-provisioning-3741) |
| 5 | [Workstation GPOs](05-workstation-group-policy-security.md) | Lock, firewall, USB write restriction | [42–50](evidence-index.md#phase-5--workstation-security-gpos-4250) |
| 6 | [NTFS + SMB shares](06-department-file-shares-and-access-control.md) | Four department shares, access isolation | [51–58](evidence-index.md#phase-6--file-share-access-controls-5158) |
| 7 | [DHCP and DNS troubleshooting](07-dhcp-and-dns-troubleshooting.md) | Scope .100–.200, DNS/PTR checks | [59–70](evidence-index.md#phase-7--dhcp-and-dns-5970) |
| 8 | [AD auditing](08-security-auditing-and-event-validation.md) | 4720, 4726, 4728, 4730 | [71–77](evidence-index.md#phase-8--security-auditing-7177) |
| 9 | [Authentication and lockouts](09-authentication-and-account-lockout-incident.md) | 4771, 4740, 4767; cleanup | [78–88](evidence-index.md#phase-9--authentication-incidents-and-final-verification-7888) |

## Deep-dive documents

- [Configuration reference](configuration-reference.md): network addresses, OUs, groups, access matrix, GPOs, event IDs.
- [Security incident 01 — Kerberos failure](security-incident-reports/01-kerberos-failed-logon.md).
- [Security incident 02 — lockout and recovery](security-incident-reports/02-account-lockout-and-recovery.md).
- [Security incident 03 — user lifecycle auditing](security-incident-reports/03-account-lifecycle-auditing.md).
- [Security incident 04 — group administration auditing](security-incident-reports/04-group-membership-auditing.md).
- [Troubleshooting case 01 — DHCP/DNS](troubleshooting-case-studies/01-dhcp-and-dns-corrective-actions.md).
- [Troubleshooting case 02 — folder permissions](troubleshooting-case-studies/02-access-control-validation.md).
- [Operational runbook](operational-runbook.md) and [read-only verification helper](../scripts/Verify-Lab.ps1).
- [Final verification and limitations](10-verification-and-limitations.md).
- [Complete screenshot index](evidence-index.md): **108 actual screenshots**, numbered 01–89 with suffixed captures.

## Reading the evidence

Each report uses `../screenshots/filename.png` links. Screenshots are original local-lab evidence, not simulated output pasted into the repository. In the reports, **Observed** means backed by user-captured output; **Expected** means the intended outcome of a test; **Limitation** means something was not conclusively established.

All experiments were performed in a controlled virtual lab. Test accounts used for audit/lockout exercises were removed, and the domain-wide lockout threshold was left at its original value of 0.
