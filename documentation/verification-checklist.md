# Verification checklist

[Main overview](../README.md) · [174 screenshot index](evidence-index.md) · [Verification matrix](10-verification-and-limitations.md)

This checklist separates the original lab work, later tests in a live lab, and tests that run offline. The corresponding reports show which commands were executed.

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

See [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions) for the current offline test runs. These tests do not connect to a live domain controller.

## Not completed

- [ ] Actual write-denial attempt to a disposable USB storage device.
- [ ] Packet-by-packet root-cause proof and full remediation for intermittent `nslookup` warnings.
- [ ] Independent idle timing proving Windows locked at precisely 600 seconds.
- [ ] End-to-end effective SMB testing for all 30 original accounts.
- [ ] Live AD negative/error-path and partial-failure reruns on the clone (the mock suite is not equivalent).
- [ ] Run the authentication analyzer on the actual retained Security log and review false positives.
- [x] Independently verified the exact two SHA-256 values from screenshot 0097 against archived script and CSV bytes; both match. CI now checks them.
## Evidence and maintenance checks

- [x] Automated checks cover local Markdown links, screenshot naming, screenshot-index coverage, and historical file hashes.
- [ ] Visually inspect each screenshot for passwords, personal information, tokens, or unrelated windows before sharing it publicly.
- [ ] Spot-check screenshot captions and linked output after future documentation changes.
- [ ] Review new code and logs for sensitive values before committing.

**Lab safety:** Keep the cloned DC01 on `CORP-LAB-TEST`, separate from the original `CORP-LAB` network. The clone has the same domain-controller identity and must not be used as another DC in the original network.
