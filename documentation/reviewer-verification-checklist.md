# Reviewer verification checklist and reproducibility record

[← README](../README.md) · [Code guide](../scripts/README.md) · [Historical evidence index](evidence-index.md)

This document separates **historical evidence (observed)** from **new tools (unverified)**. Do not check a task as complete until the command has been run and its actual output retained. Screenshots already in this repository describe the November 2026 training run only.

## A. Verify the historical evidence without changing the lab

| Check | Evidence | Status |
|---|---|---|
| Domain identity and installed roles | Screenshots 10a–10c | Historical screenshot |
| 30 accounts, group counts 8/7/8/7 | Screenshot 40 and final screenshot 88 | Historical screenshot |
| Workstation domain membership | Screenshots 34–35 | Historical screenshot |
| GPO application and firewall profile defaults | Screenshots 47a–47b | Historical screenshot |
| USB deny-write registry state (not USB write test) | Screenshot 50b | Historical screenshot |
| NTFS and SMB group assignments | Screenshots 52a–d, 53, 55b | Historical screenshot |
| Two employee access tests | Screenshots 56–58 | Historical screenshot; not full matrix |
| DHCP lease and reverse DNS record | Screenshots 63 and 67–70 | Historical screenshot; timeout still open |
| Security audit events | 74b, 75–77, 80a, 85–86 | Historical screenshot |
| Test account / PSO removal | Screenshots 87–88 | Historical screenshot |

## B. New code: execution checklist

- [x] Offline synthetic CSV validator tests passed in [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43669522297); includes group mapping and duplicate rejection.
- [x] Offline authentication analyzer scenarios passed in [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43669522297); includes positive correlation and negative split-source/status cases.
- [x] Added and passed ten mocked AD provisioning safety scenarios (plan-only, WhatIf, wrong domain, missing OU/group, unexpected OU, disabled creation, group-add failure, and rerun repair) in [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43677960000). Mock only; not a DC01 execution.
- [x] Added and passed synthetic complete 30-user reconciliation and negative discrepancy tests in the same CI run; the actual DC01 roster is still unverified.
- [ ] On a VM snapshot of DC01, run scripts/Verify-Lab.ps1; inspect **all** failed/skipped sections.
- [ ] Run scripts/Invoke-LabEmployeeProvisioning.ps1 with **no -Apply**, capture planned actions.
- [ ] Run with -Apply -WhatIf, confirm no directory changes; only then consider an authorized write-mode test.
- [ ] Validate the reconstructed onboarding script's rerun behavior after a controlled partial state.
- [ ] Run the analyzer on the DC01 Security log with enough HoursBack for events to exist.
- [x] Review and archive supplied 2,599-byte original script; confirmed size and visible content against DC01 screenshots (not VM hash).
- [x] Archive the original fictional 28-row CSV alongside the historical PowerShell source.
- [x] Add offline assertions for the archived CSV's row count, per-department counts, usernames, and documented file sizes; this does not compare against the live domain.
- [ ] Compare both archived file hashes against DC01; export the complete 30-user roster and confirm the two separately created accounts (`sjohnson`, `amorgan`) are the only records outside the CSV.
- [ ] Run [Test-LabRoster.ps1](../scripts/Test-LabRoster.ps1) in `-Live` read-only mode on DC01 and retain actual output; offline synthetic test coverage alone cannot complete this item.
- [ ] Publish a dated file containing **actual** test commands, input, output, exceptions, and fixes. Never generate fictitious terminal results.

**Current status (2026-11-15 UTC):** The expanded successful [GitHub Actions run](https://github.com/raheem-code124/active-directory-security-lab/actions/runs/43677960000) includes the archived files, synthetic roster reconciliation, mock AD provisioning negative/error handling, and repository integrity tests. These are offline checks only. **All DC01/CLIENT01 live execution checks above remain pending.**

## C. Planned hands-on tests (not yet completed)

**DNS timeout:** On CLIENT01, compare repeated A/PTR/AAAA queries with and without a trailing dot. Capture DNS request/response traffic (for example with Wireshark in the isolated lab), query types, server address, response codes, and timing. Investigate whether timeouts are from search-suffix expansion, retries, an unsupported record type, or something else. Record what actually happened; do not declare a cause from the initial symptom alone.

**NTFS/SMB access:** For each department, sign in as a fictional user whose only department access should match the group. Record whoami, correct-share read/write, and attempted cross-department read/write under **that user's token**, not an elevated Administrator token. Only write harmless test files in the isolated lab. Remove them afterward. Verify effective NTFS and SMB permission layers independently.

**USB deny-write:** Attach a disposable virtual USB mass-storage device, prove a benign test file can be written before the GPO is applied, apply and refresh the restriction, then repeat the write and capture the actual result. Use a throwaway device; no production media. Do not claim enforcement until observed.

**Inactivity lock:** Record an actual start time, wait without touching the client for 600 seconds, and capture the observed lock time. A static Windows lock screen alone is insufficient to prove the exact configured delay.

**Authentication detection:** Test at least one positive synthetic sequence, an isolated wrong password, failures from two distinct sources, and an account lockout with no nearby 4771 sequence. Report expected false positives and missing-data limits. Run on live Security logs only with appropriate permission.

## D. Roadmap status (evidence-based)

| Priority | Improvement | Status as of November 15, 2026 |
|---|---|---|
| 1 | Verify new read-only scripts on DC01 | **Pending live evidence** |
| 1 | Reconcile the full roster and compare original DC01 file hashes | **Offline tests passed; live roster/hash comparison pending** |
| 1 | Public visibility after privacy review | **Private; privacy review and publication pending** |
| 2 | Investigate DNS timeout traffic | **Pending live packet capture** |
| 2 | Test SMB allow/deny across all four departments | **Pending live permission tests** |
| 2 | Prove removable-storage write denial | **Pending live USB test** |
| 3 | Execute new provisioning tool on disposable VM clone | **Pending isolated AD runtime test** |
| 3 | Add stronger automated negative/error-handling tests | **Completed for the mock/CSV suite and passing CI; additional live failure-path verification pending** |

No score increase is claimed solely from passing offline CI. A VM test is considered complete only with real command output, a date, and retained evidence.

## E. Architecture and publication

- [ ] Explain DC01 SMB/DHCP service consolidation as a lab simplification. A production-style version should use a separate domain member file server and multiple DCs where justified.
- [ ] Inspect every image for live passwords, personal data, tokens, or internal production addresses before public visibility.
- [ ] Confirm the original source and reference code are not mislabeled.
- [ ] Review README links, architecture display, and all referenced screenshots.
- [ ] Change repository visibility to public **only after review**.

A reviewer should judge the lab on what is demonstrably tested, not the number of screenshots or added source files.
