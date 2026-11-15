# PowerShell reference scripts — new, read-only helpers

These scripts were **written for the published portfolio after the hands-on lab**. They are supplied for review and future validation; they are **not** represented as the exact automation scripts used during the VM build and are **not claimed to have been executed in the evidence screenshots**.

## Files

| Script | Intended run location | Purpose | AD state changes? |
|---|---|---|---|
| [`Verify-Lab.ps1`](Verify-Lab.ps1) | DC01, PowerShell with AD/DHCP/DNS/SMB modules | Read-only inventory and validation against evidence-backed expected values | **No** |
| [`Export-SecurityEvents.ps1`](Export-SecurityEvents.ps1) | DC01, PowerShell with Security log read permission | Query known event IDs and optionally export local CSV for analysis | **No** |

## How to run (after review)

```powershell
# From the scripts folder on DC01:
.\Verify-Lab.ps1

# Search recent security events; optionally write local sanitized CSV.
.\Export-SecurityEvents.ps1 -HoursBack 24
.\Export-SecurityEvents.ps1 -HoursBack 24 -OutputPath "C:\Temp\CORP-Lab-EventExport.csv"
```

The verification script reports mismatches; it does not fix them. The export script can write a **local CSV** and never uploads it. Inspect output for personally identifying information before sharing.

### Original onboarding script

The actual deployment was performed from files inside DC01, including `C:\ADLab\Scripts\employees.csv` and `C:\ADLab\Scripts\Create-Employees-v3.ps1` (seen in the screenshots). The original source has **not been exported or reviewed byte-for-byte**, so we intentionally did **not** fabricate a replacement labeled as the original. The [directory automation report](../documentation/02-active-directory-structure-and-automation.md) explains the verified workflow and known errors.

### Script security

- Run only on systems you administer.
- Requires the relevant Windows Server modules and log permissions.
- Do not bypass domain policies or turn off auditing to make checks pass.
- Scripts are supplied as **reviewable examples**; no automated tests in GitHub Actions were run.
