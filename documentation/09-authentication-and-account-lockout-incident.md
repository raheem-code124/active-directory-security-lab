# Phase 9 — Failed authentication, account lockout, recovery, and cleanup

[← Phase 8](08-security-auditing-and-event-validation.md) · [Documentation index](README.md) · [Next: Final verification →](10-verification-and-limitations.md)

## Objective

Simulate realistic authentication failures on CLIENT01 and investigate resulting DC01 security logs. Reproduce an account lockout **without changing the default domain password policy for all employees**, then unlock and remove temporary objects.

## Part A — Enable Kerberos auditing

Edited the existing `GPO-DC-Security-Auditing` under:

**Computer Configuration → Policies → Windows Settings → Security Settings → Advanced Audit Policy Configuration → Audit Policies → Account Logon → Audit Kerberos Authentication Service**

Selected **Success and Failure**, refreshed policy on DC01, and verified the effective configuration:

```powershell
gpupdate /force
auditpol /get /subcategory:"Kerberos Authentication Service"
```

**Observed:** `Kerberos Authentication Service   Success and Failure`. [Screenshot 78](../screenshots/78-kerberos-authentication-auditing-enabled.png).

## Part B — Failed-password simulation and investigation

From CLIENT01, signed in as `CORP\sjohnson`, ran:

```cmd
runas /user:CORP\amorgan cmd
```

Entered an intentionally incorrect password. The client returned `RUNAS ERROR` with **1326: The user name or password is incorrect**. [Screenshot 79](../screenshots/79-failed-domain-authentication-simulation.png).

On DC01, searched for Event ID `4771`:

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='Security'
  Id=4771
  StartTime=(Get-Date).AddHours(-1)
} | Where-Object {$_.Message -match 'amorgan'} |
  Select-Object -First 3 TimeCreated,Id,Message | Format-List
```

**Observed:** `Kerberos pre-authentication failed`, username `amorgan`, failure code **`0x18`** (bad password), source `::ffff:192.168.50.100` (IPv4-mapped CLIENT01), and multiple event records around the simulated attempt. Multiple events were captured, but the number of manual password entries **cannot be inferred** from the event count alone.

Evidence: [80a](../screenshots/80a-kerberos-failed-authentication-event.png) · [80b](../screenshots/80b-kerberos-failure-event-details.png) · [80c](../screenshots/80c-kerberos-additional-failure-records.png).

## Part C — Account lockout policy planning

The **existing default domain password policy** had:

| Setting | Observed |
|---|---|
| `LockoutThreshold` | **0** (automatic lockout disabled) |
| `LockoutDuration` | 00:10:00 |
| `LockoutObservationWindow` | 00:10:00 |

Evidence: [81](../screenshots/81-active-directory-account-lockout-policy.png).

The experiment therefore used a dedicated temporary account (`lockout.test`) and a **fine-grained password policy** applying only to that account.

```powershell
# Password entered interactively; no literal credentials recorded in this repo.
New-ADUser -Name "Lockout Test User" -SamAccountName "lockout.test" `
  -Path "OU=IT,OU=Company,DC=corp,DC=example,DC=test" `
  -AccountPassword (Read-Host "Enter temporary test password" -AsSecureString) `
  -Enabled $true -ChangePasswordAtLogon $false `
  -Description "Temporary account for lockout simulation"

New-ADFineGrainedPasswordPolicy -Name "PSO-Lockout-Test" -Precedence 100 `
  -ComplexityEnabled $true -MinPasswordLength 12 -PasswordHistoryCount 5 `
  -MinPasswordAge "0.00:00:00" -MaxPasswordAge "90.00:00:00" `
  -LockoutThreshold 3 -LockoutDuration "0.00:10:00" `
  -LockoutObservationWindow "0.00:10:00" -ReversibleEncryptionEnabled $false

Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Lockout-Test" -Subjects "lockout.test"

Get-ADUserResultantPasswordPolicy "lockout.test" |
  Select-Object Name,LockoutThreshold,LockoutDuration,LockoutObservationWindow
```

**Verified:** `PSO-Lockout-Test`, threshold **3**, both time intervals **10 minutes**. Evidence: [82 test user](../screenshots/82-lockout-test-account-created.png) · [83 test policy](../screenshots/83-test-account-lockout-policy-configured.png).

## Part D — Trigger, find, and resolve lockout

From CLIENT01, used `runas /user:CORP\lockout.test cmd` with incorrect credentials. DC01 checks showed the count growing from `BadPwdCount=1, LockedOut=False` to **`BadPwdCount=3, LockedOut=True`**, with the lockout at 8:39:47 PM.

Evidence: [84a failed attempts](../screenshots/84a-account-lockout-failed-attempts.png) · [84b account status](../screenshots/84b-account-lockout-confirmed.png).

Queried DC01's Security log for `4740`:

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='Security'; Id=4740; StartTime=(Get-Date).AddHours(-1)
} | Where-Object {$_.Message -match 'lockout\.test'} |
  Select-Object -First 1 TimeCreated,Id,Message | Format-List
```

**Observed Event 4740:** `lockout.test` locked out; **Caller Computer Name: CLIENT01**; Subject account `DC01$` (the machine account recording the event), not the human who guessed the password. [Screenshot 85](../screenshots/85-account-lockout-event-4740-investigation.png).

The administrator then unlocked the account and verified `LockedOut=False`:

```powershell
Unlock-ADAccount -Identity "lockout.test"
Get-ADUser "lockout.test" -Properties LockedOut | Select-Object Name,LockedOut
```

**Observed Event 4767:** `CORP\Administrator` unlocked `lockout.test` at 8:42:12 PM. [Screenshot 86](../screenshots/86-account-unlock-and-security-event-verification.png).

## Part E — Remove temporary objects and revalidate

```powershell
Remove-ADUser -Identity "lockout.test" -Confirm:$false
Remove-ADFineGrainedPasswordPolicy -Identity "PSO-Lockout-Test" -Confirm:$false

Get-ADUser -Filter "SamAccountName -eq 'lockout.test'"
Get-ADFineGrainedPasswordPolicy -Filter "Name -eq 'PSO-Lockout-Test'"
```

**Observed:** Both searches returned no objects. [Screenshot 87](../screenshots/87-lockout-test-environment-cleanup.png).

Ran final user/group and audit checks: 30 accounts, group counts IT 8 / HR 7 / Finance 8 / Operations 7, audit settings for User Account Management, Security Group Management, and Kerberos Authentication Service still `Success and Failure`. [Screenshot 88](../screenshots/88-final-active-directory-security-verification.png).

## Incident response lessons

- A failed `runas` can be investigated through domain-side Kerberos event logs.
- `4771` includes the target account, failure code, and client address (when recorded).
- `4740` identifies the locked account and, here, the caller workstation.
- A single failed attempt does **not** by itself prove an attack.
- Dedicated test identities and scoped fine-grained policies reduce collateral effects.
- Verify recovery and clean up after simulation.
- Auditing creates evidence; alert rules, correlation, escalation and SIEM collection are future work.

**Detailed write-ups:** [Kerberos failure](security-incident-reports/01-kerberos-failed-logon.md) · [Account lockout and recovery](security-incident-reports/02-account-lockout-and-recovery.md).
