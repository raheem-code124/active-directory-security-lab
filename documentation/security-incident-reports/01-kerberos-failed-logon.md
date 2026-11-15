# Security incident report 01 — Failed Kerberos preauthentication

**Case ID:** SEC-01  
**Type:** Controlled authentication-failure simulation  
**Environment:** CLIENT01 → DC01 / `corp.example.test`  
**Event:** Windows Security **4771**  
**Case status:** Investigated; expected failed sign-in was recorded; no compromise claimed.

## Incident at a glance

| Item | Observed |
|---|---|
| Target account | `CORP\amorgan` (Alex Morgan, IT) |
| Source client | `CLIENT01` |
| Source address | `::ffff:192.168.50.100` (IPv4-mapped IPv6 display of 192.168.50.100) |
| Service | `krbtgt/CORP` |
| Event ID | 4771 — Kerberos pre-authentication failed |
| Failure code | `0x18` — incorrect password |
| Event time | Multiple events near 8:29–8:31 PM, Nov 14, 2026 |
| Trigger | Deliberately entered incorrect password with `runas` from Sarah Johnson's client session |
| Scope | Isolated educational lab, no unauthorized access |

## Background

DC01 was already configured with `GPO-DC-Security-Auditing` to audit Kerberos Authentication Service success and failure, confirmed with `auditpol` ([78](../../screenshots/0078-kerberos-authentication-auditing-enabled.png)). The client could reach DC01, obtain DHCP/DNS settings, and authenticate domain users.

## Detection and investigation timeline

**1 — Trigger on CLIENT01**

```cmd
runas /user:CORP\amorgan cmd
```

An intentionally incorrect password was entered. Windows returned:

```text
RUNAS ERROR: Unable to run - cmd
1326: The user name or password is incorrect.
```

See [Screenshot 79](../../screenshots/0079-failed-domain-authentication-simulation.png).

**2 — Search on DC01**

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='Security'; Id=4771; StartTime=(Get-Date).AddHours(-1)
} | Where-Object {$_.Message -match 'amorgan'} |
  Select-Object -First 3 TimeCreated,Id,Message | Format-List
```

The output contained events at approximately 8:29:43, 8:30:17, and 8:30:55 PM. Their content identified the account `amorgan`, client `192.168.50.100`, service `krbtgt/CORP`, and error `0x18`. Evidence: [80a](../../screenshots/0080a-kerberos-failed-authentication-event.png), [80b](../../screenshots/0080b-kerberos-failure-event-details.png), [80c](../../screenshots/0080c-kerberos-additional-failure-records.png).

**3 — Triage interpretation**

- `0x18` supports an incorrect-password conclusion.
- The source IP matches CLIENT01's confirmed DHCP lease.
- Multiple 4771 records do not necessarily equal that many **human** login attempts; the service can create multiple requests.
- The test was deliberately controlled and therefore **not a true intrusion**.

## Security significance

A real security analyst could correlate repeated 4771 records with account sensitivity, login success, baseline behavior, device identity, lockout events and change-management context. High volume could be consistent with guessing, a stale service password, or a misconfigured client; this case alone does **not** distinguish among those without additional context.

## Response and disposition

No password was changed and no employee account was intentionally locked during this first simulation. Further investigation continued using a **dedicated test account** in [incident 02](02-account-lockout-and-recovery.md), which avoided affecting Alex's actual lab account.

**Learning:** Audit policy → controlled failing action → query → decode failure code → identify source/target → assess context.  
[Parent phase report](../09-authentication-and-account-lockout-incident.md).
