# Security incident report 02 — Account lockout and administrator recovery

**Case ID:** SEC-02  
**Type:** Controlled account-lockout and recovery exercise  
**Target:** `CORP\lockout.test` (dedicated, temporary identity)  
**Status:** Lockout reproduced, source identified, account unlocked, temporary account/policy removed.

## Incident at a glance

| Item | Evidence-backed finding |
|---|---|
| Default domain lockout threshold | `0` (no automatic lockout under default domain policy) |
| Test-scoped policy | `PSO-Lockout-Test` |
| Test lockout threshold | 3 bad password attempts |
| Lockout duration | 10 minutes |
| Observation window | 10 minutes |
| Bad password count | Increased from 1 to 3 |
| Locked state | `False → True → False` |
| Lockout event | **4740**, 8:39:47 PM, Nov 14, 2026 |
| Caller computer | `CLIENT01` |
| Unlock event | **4767**, 8:42:12 PM |
| Unlocking identity | `CORP\Administrator` |
| Cleanup | `lockout.test` and `PSO-Lockout-Test` deleted |

## Why a separate test identity?

The domain-wide threshold was `0`; making it `3` could cause other fictional employees' accounts to lock during experimentation. To limit effects, a **fine-grained password policy** was applied directly to one test user. The final review showed all 30 original employee accounts and four department memberships intact.

### 1. Establish safe controls

On DC01:

```powershell
Get-ADDefaultDomainPasswordPolicy |
  Select-Object LockoutThreshold,LockoutDuration,LockoutObservationWindow

Get-ADUserResultantPasswordPolicy -Identity "lockout.test" |
  Select-Object Name,LockoutThreshold,LockoutDuration,LockoutObservationWindow
```

**Observed:** default `LockoutThreshold=0`; test `PSO-Lockout-Test` threshold `3`, 10-minute duration and observation window. Evidence: [81](../../screenshots/0081-active-directory-account-lockout-policy.png), [82](../../screenshots/0082-lockout-test-account-created.png), [83](../../screenshots/0083-test-account-lockout-policy-configured.png).

### 2. Generate a failed authentication event from CLIENT01

```cmd
runas /user:CORP\lockout.test cmd
```

The deliberate incorrect password yielded `RUNAS ERROR 1326`. DC01's initial state showed `BadPwdCount=1, LockedOut=False`. After subsequent controlled wrong-password attempts, DC01 showed **`BadPwdCount=3, LockedOut=True`**.

Evidence: [84a client commands](../../screenshots/0084a-account-lockout-failed-attempts.png) · [84b before/after](../../screenshots/0084b-account-lockout-confirmed.png).

### 3. Investigate the lockout on DC01

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='Security'; Id=4740; StartTime=(Get-Date).AddHours(-1)
} | Where-Object {$_.Message -match 'lockout\.test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

The **4740** event identified the locked account `lockout.test` and **Caller Computer Name: CLIENT01**. Its **Subject** showed `DC01$` with SYSTEM SID `S-1-5-18`; that's the domain controller's logging identity, not proof that someone was interactively using DC01.

Evidence: [85 event 4740](../../screenshots/0085-account-lockout-event-4740-investigation.png).

### 4. Restore access

```powershell
Unlock-ADAccount -Identity "lockout.test"
Get-ADUser "lockout.test" -Properties LockedOut | Select-Object Name,LockedOut
```

After running the unlock command, `LockedOut=False`. The event log showed **4767**, with `CORP\Administrator` as the subject and `lockout.test` as the target. Evidence: [86 unlock and event](../../screenshots/0086-account-unlock-and-security-event-verification.png).

### 5. Return test environment to baseline

```powershell
Remove-ADUser -Identity "lockout.test" -Confirm:$false
Remove-ADFineGrainedPasswordPolicy -Identity "PSO-Lockout-Test" -Confirm:$false

Get-ADUser -Filter "SamAccountName -eq 'lockout.test'"
Get-ADFineGrainedPasswordPolicy -Filter "Name -eq 'PSO-Lockout-Test'"
```

Both searches returned no results. Evidence: [87 cleanup](../../screenshots/0087-lockout-test-environment-cleanup.png).

### 6. Confirm original directory remained intact

Final output showed 30 Company OU users, groups at **8/7/8/7**, and auditing still enabled for relevant categories. Evidence: [88](../../screenshots/0088-final-active-directory-security-verification.png).

## Root cause

**Known because intentionally induced:** Repeated incorrect password attempts from CLIENT01 against `lockout.test` caused the scoped three-attempt lockout threshold to be reached. This was not an unexpected attack and did not implicate other users.

## How this maps to a real help-desk/security case

1. Confirm the employee's account is actually locked.
2. Inspect **4740** to find target account and caller computer.
3. Correlate failed authentication events such as **4771** with timestamps and address.
4. Check whether password guessing, stale stored credentials, scheduled jobs or service credentials could explain failures.
5. Verify the person requesting access and follow the organization's unlock procedure.
6. Document **4767** and confirm successful resolution; investigate underlying cause to prevent recurrence.

A real organization would enforce an approved lockout policy and monitoring process; the threshold of 3 was chosen for this contained demonstration only.

**Outcome:** Detection, investigation, remediation and post-incident verification, all evidenced.  
[Parent phase report](../09-authentication-and-account-lockout-incident.md).
