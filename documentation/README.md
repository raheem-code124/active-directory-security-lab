# Technical documentation and evidence guide

[Project overview](../README.md) · [All 174 screenshots](evidence-index.md) · [Final verification matrix](10-verification-and-limitations.md)

This record separates the **original hands-on lab** from **later follow-up verification**. Screenshot filenames have four-digit prefixes (for example `0113` or `0127a`); original milestone numbers and letter suffixes remain unchanged. Step `0117` has no screenshot and was not filled with invented evidence.

## Original lab phases

| Phase | Report | Outcome |
|---|---|---|
| 1 | [Server and domain controller](01-environment-and-domain-controller.md) | DC01, AD DS/DNS, static IP |
| 2 | [Directory and initial onboarding](02-active-directory-structure-and-automation.md) | Company OUs, groups, corrected onboarding |
| 3 | [CLIENT01 and domain join](03-client-domain-join.md) | Domain-joined Windows client |
| 4 | [30-user provisioning](04-bulk-provisioning-and-validation.md) | Original 30 fictional employees |
| 5 | [Workstation GPOs](05-workstation-group-policy-security.md) | Lock, firewall, removable-disk policy |
| 6 | [NTFS and SMB sharing](06-department-file-shares-and-access-control.md) | Four group-restricted shares |
| 7 | [DHCP and DNS](07-dhcp-and-dns-troubleshooting.md) | Lease, DNS options and PTR repair |
| 8 | [DC security auditing](08-security-auditing-and-event-validation.md) | User/group lifecycle events |
| 9 | [Kerberos failure and lockout](09-authentication-and-account-lockout-incident.md) | Simulated incident and recovery |
| 10 | [Final verification and known limits](10-verification-and-limitations.md) | Grounded control test matrix |

## Follow-up evidence (November 2026)

| Report | Tested work |
|---|---|
| [11 — Account reconciliation and source checks](11-live-roster-and-integrity-verification.md) | 21 live configuration checks and original 30-user roster match |
| [12 — CLIENT01 DNS investigation](12-dns-follow-up-investigation.md) | Suffix-debug, Packet Monitor, recursion and routing |
| [13 — Department share-access tests](13-department-access-control-follow-up.md) | Four user identities, 16 directory checks, allowed and denied writes |
| [14 — USB policy and isolated provisioning](14-isolated-provisioning-validation.md) | Policy evidence; disconnected clone plan/WhatIf/Apply |
| [Support ticket AD-001](support-tickets/AD-001-hr-password-reset.md) | Fictional HR password reset, sign-in and access validation |

## Reference materials

[Configuration reference](configuration-reference.md) · [Operational runbook](operational-runbook.md) · [Reviewer checklist](reviewer-verification-checklist.md) · [Historical onboarding code review](code-review-original-onboarding.md) · [Incident reports](security-incident-reports/01-kerberos-failed-logon.md) · [Case studies](troubleshooting-case-studies/01-dhcp-and-dns-corrective-actions.md)

**Evidence rule:** Observed command results are distinct from a script's intended behavior. The original domain remained at 30 users, while a disconnected clone reached 34. USB policy was configured but no physical write was attempted. DNS capture artifacts exist but do not prove a fully resolved timeout issue.
