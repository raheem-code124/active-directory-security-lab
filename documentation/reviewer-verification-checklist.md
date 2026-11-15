# Reviewer checklist — evidence and reproducibility

[Main overview](../README.md) · [174 screenshot index](evidence-index.md) · [Verification matrix](10-verification-and-limitations.md)

Do not confuse historical work, follow-up live execution, or offline synthetic tests. A file existing in GitHub is **not** proof the code ran.

## Completed live tests with screenshot evidence

- [x] Original `corp.example.test` baseline: 30 users, security-group counts IT 8 / HR 7 / Finance 8 / Operations 7.
- [x] `Verify-Lab.ps1` read-only live DC01 run: **21 checks, 0 mismatches, 0 section errors** (script's listed scope only).
- [x] `Test-LabRoster.ps1 -Live`: live roster matches archived 28-record employee CSV plus `amorgan` and `sjohnson`.
- [x] Four employee identities tested for directory access against all four shares: 16 allow/deny checks.
- [x] Four permitted file create/read tests and four cross-department denied write tests under non-admin employee sessions.
- [x] Temporary test files from follow-up SMB testing cleaned up; earlier historical Finance file preserved.
- [x] Simulated HR account reset, domain sign-in and effective permissions under `mpatel`.
- [x] Group Policy application and USB deny-write registry state checked on CLIENT01.
- [x] DNS client suffix tests, verbose name-resolution traces, filtered Packet Monitor capture and export.
- [x] DC01 recursion, forwarder, root-hint and IPv4 routing settings inspected.
- [x] Isolated clone started from separate VirtualBox internal network and verified with 30 baseline users.
- [x] New provisioning plan-only and `-Apply -WhatIf` runs left 30 users unchanged.
- [x] Controlled Apply on clone created four disabled users, count rose to 34; group and disabled flags correct.
- [x] Plan-only rerun reported `ALREADY_CORRECT` for each new account.
- [x] Original account lifecycle, Kerberos failure and fine-grained account lockout/recovery logs captured.

See [follow-up reports 11–14](README.md#follow-up-evidence-november-2026).

## Offline-only or source-level checks

- [x] CSV validation, historical row-count assertions and synthetic account reconciliation.
- [x] Authentication correlation tests with fabricated Security-event records.
- [x] Mock AD provisioning safety/failure-path cases.
- [x] Historical original script separated from later safer reconstruction.
- [x] Screenshot links and repository inventory addressed by `tests/Test-RepoStructure.ps1`.

The previous [successful CI run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43677960000) pertains to the earlier commit. Review [current workflow status](https://github.com/raheem-code124/active-directory-security-lab/actions) after the screenshot renaming commit.

## Not completed

- [ ] Actual write-denial attempt to a disposable USB storage device.
- [ ] Packet-by-packet root-cause proof and full remediation for intermittent `nslookup` warnings.
- [ ] Independent idle timing proving Windows locked at precisely 600 seconds.
- [ ] End-to-end effective SMB testing for all 30 original accounts.
- [ ] Live AD negative/error-path and partial-failure reruns on the clone (the mock suite is not equivalent).
- [ ] Run the authentication analyzer on the actual retained Security log and review false positives.
- [x] Independently verified the exact two SHA-256 values from screenshot 0097 against archived script and CSV bytes; both match. CI now checks them.
- [ ] Manual privacy review of **every** screenshot (passwords, tokens, personal info, unrelated windows).

## Before making public

- [ ] Verify current GitHub Actions jobs and local Markdown links.
- [ ] Click a sample of image links for each period; confirm screenshot numbers and captions point to the intended output.
- [ ] Open every image for privacy checks. Never upload VM disks, ISOs or unredacted secrets.
- [ ] Keep the clone disconnected from `CORP-LAB`. Do not attempt to use a cloned same-identity DC as a production redundancy mechanism.
- [ ] Only after review, decide whether to make the repository public.

The repository's final evaluation should be based on **demonstrated, properly scoped outcomes**, not inflated screenshot totals.
