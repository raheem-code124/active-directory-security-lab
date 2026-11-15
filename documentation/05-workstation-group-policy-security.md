# Phase 5 — Centrally enforce workstation security

[← Phase 4](04-bulk-provisioning-and-validation.md) · [Documentation index](README.md) · [Next: File shares →](06-department-file-shares-and-access-control.md)

## Objective

Use **Group Policy** to enforce repeatable security controls on the domain-joined Windows client. Separate each control into a dedicated GPO and link these GPOs to `Company/Workstations` rather than the whole domain. Verify the machine actually received the settings.

## Applied GPOs

| GPO | Intended control | Link |
|---|---|---|
| `GPO-Workstation-Security-Baseline` | Lock computer after 600 seconds of inactivity | Company → Workstations |
| `GPO-Workstation-Firewall` | Windows Defender Firewall enabled; default inbound deny, outbound allow | Company → Workstations |
| `GPO-Workstation-USB-Restriction` | Deny writing to removable disks | Company → Workstations |

These are **computer** policies; their targeting depends on the CLIENT01 computer account's OU, not which department user is logged in.

### A. Inactivity lock (screenshots 42–44)

1. Created the workstation security baseline GPO.
2. Edited **Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options → Interactive logon: Machine inactivity limit**.
3. Enabled a machine inactivity limit of `600` seconds (10 minutes).
4. Applied machine policy on CLIENT01 with `gpupdate /force`.
5. Verified the effective setting by querying `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`, where `InactivityTimeoutSecs = 0x258` (600 decimal).
6. Left the client idle and observed the Windows lock/sign-in screen, providing a behavior test as well as a configuration check.

```powershell
gpupdate /force
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Evidence: [42 GPO editor](../screenshots/0042-workstation-auto-lock-gpo.png) · [43 applied/registry](../screenshots/0043-workstation-gpo-application-verification.png) · [44 lock screen](../screenshots/0044-workstation-auto-lock-test.png).

**Why:** Short idle-time locks reduce the risk that someone can use an unattended workstation session. This does not replace authentication or screen-lock habits.

### B. Windows Defender Firewall (screenshots 45–47)

1. Created `GPO-Workstation-Firewall` and linked it to the Workstations OU.
2. Configured Windows Defender Firewall with Advanced Security for three profiles:
   - Domain: enabled, inbound Block, outbound Allow.
   - Private: enabled, inbound Block, outbound Allow.
   - Public: enabled, inbound Block, outbound Allow.
3. Refreshed Group Policy and verified both the applied-GPO list and effective profiles.

```powershell
gpupdate /force
gpresult /r /scope computer
Get-NetFirewallProfile -PolicyStore ActiveStore |
  Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction |
  Format-Table
```

**Observed result:** Domain, Private, Public were `Enabled=True`, `DefaultInboundAction=Block`, `DefaultOutboundAction=Allow`. The `gpresult` list showed both baseline and firewall GPOs.

Evidence: [45 configuration](../screenshots/0045-workstation-firewall-policy-configured.png) · [46 linked](../screenshots/0046-workstation-firewall-gpo-linked.png) · [47a GPOs](../screenshots/0047a-workstation-gpo-verification.png) · [47b profiles](../screenshots/0047b-workstation-firewall-verification.png).

**Why:** Establishes a default network exposure posture while allowing normal outbound client communication. The lab confirmed the profile defaults; it did not enumerate every possible application-specific firewall rule.

### C. Removable-disk write restriction (screenshots 48–50)

1. Created `GPO-Workstation-USB-Restriction` and linked it to Workstations.
2. Opened **Computer Configuration → Policies → Administrative Templates → System → Removable Storage Access**.
3. Enabled **Removable Disks: Deny write access**.
4. Refreshed policy on CLIENT01.
5. Verified `GPO-Workstation-USB-Restriction` in applied-GPO output.
6. Verified the backing registry policy value `Deny_Write = 1` at `HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}`.

```powershell
gpresult /r /scope computer
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}' -Name Deny_Write
```

Evidence: [48 policy](../screenshots/0048-workstation-usb-write-restriction-gpo.png) · [49 link](../screenshots/0049-workstation-usb-restriction-linked.png) · [50a applied](../screenshots/0050a-usb-restriction-gpo-applied.png) · [50b registry](../screenshots/0050b-usb-write-restriction-registry-verified.png).

**Important limitation:** The GPO and registry state were verified, but this lab did **not** demonstrate writing to a physical/virtual USB flash drive and receiving an access-denied error. Do not describe this as a completed live USB transfer block test.

## Verification checklist

| Check | Evidence | Result |
|---|---|---|
| Workstation object in correct OU | 41 | Confirmed |
| Baseline GPO applied | 43, 47a | Confirmed |
| Inactivity timeout 600 s | 42, 43 | Confirmed |
| Client locked after idle | 44 | Observed |
| Firewall GPO applied | 46, 47a | Confirmed |
| All three effective firewall profiles | 47b | Enabled / Block / Allow |
| USB GPO applied | 49, 50a | Confirmed |
| USB Deny_Write policy registry | 50b | `1` |
| Physical removable disk denied | Not captured | **Not tested** |

## How this translates to operational work

A GPO visible in Group Policy Management doesn't prove client enforcement. The administrator must verify **scope**, policy application, effective Windows settings, and, when possible, behavior. The lab contains all those forms of evidence except an actual USB write attempt.

For additional details, see [configuration reference](configuration-reference.md) and [final limitations](10-verification-and-limitations.md).


## Follow-up CLIENT01 policy check — Step 0131

A later `gpresult /r /scope computer` confirmed all three GPOs applied on CLIENT01, and `reg query` returned `Deny_Write REG_DWORD 0x1` for the removable-disk storage class. The existing limitation remains: **no physical or emulated USB write attempt was tested**.

Evidence: [0131a applied GPOs](../screenshots/0131a-usb-restriction-gpo-applied.png) · [0131b registry](../screenshots/0131b-usb-write-restriction-registry-verified.png). [Related follow-up](14-isolated-provisioning-validation.md).
