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

- [ ] In PowerShell, run tests/Test-EmployeeCsv.ps1; record exact terminal output and exit status.
- [ ] Run tests/Test-AuthAnalyzer.ps1; record exact terminal output and exit status.
- [ ] On a VM snapshot of DC01, run scripts/Verify-Lab.ps1; inspect **all** failed/skipped sections.
- [ ] Run scripts/Invoke-LabEmployeeProvisioning.ps1 with **no -Apply**, capture planned actions.
- [ ] Run with -Apply -WhatIf, confirm no directory changes; only then consider an authorized write-mode test.
- [ ] Validate the reconstructed onboarding script's rerun behavior after a controlled partial state.
- [ ] Run the analyzer on the DC01 Security log with enough HoursBack for events to exist.
- [ ] Export and review the original onboarding source and CSV; compare to screenshots before publishing.
- [ ] Publish a dated file containing **actual** test commands, input, output, exceptions, and fixes. Never generate fictitious terminal results.

**Current status:** All items in B are **pending**, unless the repository is later updated with evidence. The new scripts are reviewable source, not historical or runtime validation.

## C. Planned hands-on tests (not yet completed)

**DNS timeout:** On CLIENT01, compare repeated A/PTR/AAAA queries with and without a trailing dot. Capture DNS request/response traffic (for example with Wireshark in the isolated lab), query types, server address, response codes, and timing. Investigate whether timeouts are from search-suffix expansion, retries, an unsupported record type, or something else. Record what actually happened; do not declare a cause from the initial symptom alone.

**NTFS/SMB access:** For each department, sign in as a fictional user whose only department access should match the group. Record whoami, correct-share read/write, and attempted cross-department read/write under **that user's token**, not an elevated Administrator token. Only write harmless test files in the isolated lab. Remove them afterward. Verify effective NTFS and SMB permission layers independently.

**USB deny-write:** Attach a disposable virtual USB mass-storage device, prove a benign test file can be written before the GPO is applied, apply and refresh the restriction, then repeat the write and capture the actual result. Use a throwaway device; no production media. Do not claim enforcement until observed.

**Inactivity lock:** Record an actual start time, wait without touching the client for 600 seconds, and capture the observed lock time. A static Windows lock screen alone is insufficient to prove the exact configured delay.

**Authentication detection:** Test at least one positive synthetic sequence, an isolated wrong password, failures from two distinct sources, and an account lockout with no nearby 4771 sequence. Report expected false positives and missing-data limits. Run on live Security logs only with appropriate permission.

## D. Architecture and publication

- [ ] Explain DC01 SMB/DHCP service consolidation as a lab simplification. A production-style version should use a separate domain member file server and multiple DCs where justified.
- [ ] Inspect every image for live passwords, personal data, tokens, or internal production addresses before public visibility.
- [ ] Confirm the original source and reference code are not mislabeled.
- [ ] Review README links, architecture display, and all referenced screenshots.
- [ ] Change repository visibility to public **only after review**.

A reviewer should judge the lab on what is demonstrably tested, not the number of screenshots or added source files.
