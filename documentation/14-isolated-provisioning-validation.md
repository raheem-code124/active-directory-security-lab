# Follow-up 14 — USB policy and isolated AD provisioning proof

[Scripts and safe usage](../scripts/README.md) · [Live original roster](11-live-roster-and-integrity-verification.md) · [Evidence index](evidence-index.md)

## CLIENT01 removable-storage policy (step 0131)

The client `gpresult /r /scope computer` displayed applied `GPO-Workstation-Security-Baseline`, `GPO-Workstation-Firewall` and `GPO-Workstation-USB-Restriction`. The removable-storage class registry key returned `Deny_Write REG_DWORD 0x1`.

Evidence: [Applied GPO list](../screenshots/0131a-usb-restriction-gpo-applied.png) · [Deny_Write value](../screenshots/0131b-usb-write-restriction-registry-verified.png).

**Limit:** No physical or emulated removable-storage write attempt was performed. The GPO was verified as configured/applied, not empirically proven to block a file copy.

## Safety boundary: separate VM clone

The original DC01 and CLIENT01 were powered off. A standalone `AD-LAB-DC01 Clone` was made and its VirtualBox NIC assigned to **`CORP-LAB-TEST`**, a separate internal network from the original **`CORP-LAB`**. The copied server retained hostname `DC01` and domain identity `corp.example.test` and was **not connected as a duplicate controller to the original domain network**.

Evidence: [Original DC powered off](../screenshots/0132a-dc01-powered-off-before-cloning.png) · [New VM clone](../screenshots/0132b-dc01-full-clone-created.png) · [Dedicated internal network](../screenshots/0132c-dc01-clone-network-isolation.png).

When started in isolation, the clone returned domain root `corp.example.test`, NetBIOS `CORP`, hostname `DC01`, and **30 original users** in the Company OU. The three necessary files were available through a read-only VirtualBox shared folder and copied into the clone: `Invoke-LabEmployeeProvisioning.ps1`, `EmployeeCsv.Validation.psm1` and `sample-employees.csv`.

Evidence: [AD clone baseline](../screenshots/0132d-isolated-clone-active-directory-verification.png) · [Script and CSV available](../screenshots/0132e-provisioning-files-verified.png).

## Live provisioning test results

The [new provisioning script](../scripts/Invoke-LabEmployeeProvisioning.ps1) is a **post-lab safe implementation**, not the archived historical onboarding code.

| Run | Observed behavior | Users in clone |
|---|---|---:|
| Baseline | Original domain accounts present | 30 |
| Plan without `-Apply` | Four `CREATE_DISABLED_AND_ADD_GROUP` actions; “PLAN ONLY. No AD changes” | 30 |
| `-Apply -WhatIf` | Four `What if:` previews; no new accounts | 30 |
| `-Apply -Confirm:$false` | Four creation/group-assignment `APPLIED` messages | 34 |
| Read-only validation | Every new user `Disabled=True` and `CorrectGroup=True` | 34 |
| Rerun in plan-only mode | Four `ALREADY_CORRECT` results | 34 |

Demo users and assigned groups:

- `demo.it01` → `SG_IT_Users`
- `demo.hr01` → `SG_HR_Users`
- `demo.fin01` → `SG_Finance_Users`
- `demo.ops01` → `SG_Operations_Users`

Evidence: [Planning run](../screenshots/0132f-provisioning-read-only-plan-test.png) · [WhatIf and unchanged user count](../screenshots/0132g-provisioning-whatif-safety-test.png) · [Successful Apply and count 34](../screenshots/0132h-isolated-clone-provisioning-execution.png) · [Disabled/group membership and rerun](../screenshots/0132i-provisioning-final-verification.png).

## Interpretation and limitations

**Verified live on the clone:** domain preflight worked, plan and WhatIf did not create accounts, four users were created in the correct departmental group as disabled accounts, and an unchanged plan-only rerun reported `ALREADY_CORRECT`. The original 30-account lab was not modified by this clone-only test.

The code also handles malformed inputs, unexpected OUs and missing group assignment in an [offline mocked safety suite](../tests/Test-ProvisioningSafety.ps1), but those negative/failure scenarios were **not all recreated against real AD**. A second actual `-Apply` rerun, simulated partial failure, and password-enablement workflow were not shown. The copied domain controller should **never be attached to the original CORP-LAB network**.
