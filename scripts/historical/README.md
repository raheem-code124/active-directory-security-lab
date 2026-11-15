# Archived original employee onboarding script

[← Scripts and usage](../README.md) · [Technical code review](../../documentation/code-review-original-onboarding.md)

## Provenance and scope

- **File:** [`Create-Employees-v3.ps1`](Create-Employees-v3.ps1), 2,599 bytes, Windows CRLF line endings.
- **Received:** The lab author uploaded `Create-Employees-v3.ps1.txt`, containing PowerShell source. Its **exact uploaded bytes** were committed under the original `.ps1` extension, without changing the commands or line endings.
- **Verified SHA-256 provenance:** DC01 screenshot [0097](../../screenshots/0097-original-files-sha256-verification.png) displays SHA-256 hashes of the 2,599-byte script and 778-byte CSV. An independent hash computation of the exact GitHub file bytes matched **both** values. This establishes identity to the files recorded at the VM check, not authorship or successful original execution.
- **Archived CSV SHA-256:** `88e3c2c2ddf135bf67d38eaec27b7048d5975e68d3d191c911f1621e39799fad`.
- **SHA-256 of uploaded file:** `645e351d5ace73f0ffd6ec938777f15be75d8ccdd6e757df80c70d1d1e8c2726`.
- **Inputs:** The script reads the local `C:\ADLab\Scripts\employees.csv` with **28** expected records. That [28-record CSV](employees.csv) is now archived alongside the script, preserving its 778-byte CRLF contents.
- **Outcome distinction:** The lab ultimately contained **30** employee accounts; earlier screenshots show separate IT (`amorgan`) and Finance (`sjohnson`) accounts consistent with the remaining two; a later [live read-only account reconciliation](../../documentation/11-live-roster-and-integrity-verification.md) confirmed the 30-user match.

## Safety and technical caveats

**Do not execute the historical script again on your existing lab.** It can create **enabled** accounts and modify security-group memberships. It generates strong-looking random temporary passwords but does not retain or deliver them; an administrator would have to handle password enrollment separately. It does not provide `-WhatIf`, explicit confirmation, complete per-row validation, robust run-level failure reporting, or checks for existing users located in unexpected OUs.

The source has **no hardcoded existing account password, API token, or personal production data**. The synthetic password-generation expression itself is not a secret; future generated passwords only exist transiently during execution.

The separate [`Invoke-LabEmployeeProvisioning.ps1`](../Invoke-LabEmployeeProvisioning.ps1) is a *post-lab reference implementation*, not a disguised replacement or historical original. Its safer workflow differs materially from this archived file.
