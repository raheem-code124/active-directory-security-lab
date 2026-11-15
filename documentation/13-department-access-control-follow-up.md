# Follow-up 13 — Four-department SMB/NTFS access tests

[Original SMB/NTFS configuration](06-department-file-shares-and-access-control.md) · [Support ticket AD-001](support-tickets/AD-001-hr-password-reset.md) · [Evidence index](evidence-index.md)

## Goal and environment

Demonstrate **effective** authorized and denied file-share access under actual signed-in fictional employee accounts on domain-joined CLIENT01. DC01 provides shares `\\DC01\IT`, `\\DC01\HR`, `\\DC01\Finance`, and `\\DC01\Operations`.

Server-side inspection showed each department group with SMB **Change** and NTFS **Modify** access to its own share/folder; administrators retained Full Control. A client TCP 445 test reached DC01. These are configuration/connectivity checks; the user-session tests below establish effective permissions.

Evidence: [SMB share access](../screenshots/0124-dc01-smb-share-acl-verification.png) · [NTFS ACLs](../screenshots/0125-dc01-ntfs-folder-permissions.png) · [Client SMB reachability](../screenshots/0126-client01-smb-connectivity-and-sessions.png).

## Four identities by four shares

| Logged-in user | IT | HR | Finance | Operations |
|---|---|---|---|---|
| `CORP\amorgan` (IT) | **Allowed** | Denied | Denied | Denied |
| `CORP\mpatel` (HR) | Denied | **Allowed** | Denied | Denied |
| `CORP\sjohnson` (Finance) | Denied | Denied | **Allowed** | Denied |
| `CORP\jlee` (Operations) | Denied | Denied | Denied | **Allowed** |

**Results:** 16 directory listing checks, with **4 permitted** and **12 denied** as expected.

### File write/read and denied-write tests

| Employee | Own-department file test | Unauthorized write attempt | Cleanup |
|---|---|---|---|
| Alex Morgan / IT | IT write + read worked | HR denied | IT temporary file removed |
| Maya Patel / HR | HR write + read worked | IT denied | HR temporary file removed |
| Sarah Johnson / Finance | Finance write + read worked | HR denied | New Finance test file removed |
| James Lee / Operations | Operations write + read worked | Finance denied | Operations temporary file removed |

**Results:** Four authorized create/read demonstrations, four denied cross-department write attempts, and cleanup of newly created test files. An older `finance-write-test.txt` from the original exercise was intentionally left in place.

### Per-employee screenshot evidence

- IT: [Directory matrix](../screenshots/0127a-it-employee-share-access-test.png) · [Allowed file write](../screenshots/0127b-it-authorized-write-verification.png) · [Denied HR write](../screenshots/0127c-it-unauthorized-write-denied.png) · [Cleanup](../screenshots/0127d-it-test-file-cleanup.png)
- HR: [Directory matrix](../screenshots/0128d-hr-employee-share-access-test.png) · [Allowed file write](../screenshots/0128e-hr-employee-write-access-verification.png) · [Denied IT write and cleanup](../screenshots/0128f-hr-unauthorized-write-and-cleanup.png)
- Finance: [Directory matrix](../screenshots/0129a-finance-employee-share-access-test.png) · [Allowed file write](../screenshots/0129b-finance-authorized-write-verification.png) · [Denied HR write and cleanup](../screenshots/0129c-finance-unauthorized-write-denied-and-cleanup.png)
- Operations: [Directory matrix](../screenshots/0130a-operations-employee-share-access-test.png) · [Allowed file write](../screenshots/0130b-operations-authorized-write-verification.png) · [Denied Finance write and cleanup](../screenshots/0130c-operations-unauthorized-write-and-cleanup.png)

The HR account needed a password reset during testing. That simulated help-desk exercise and subsequent access checks are documented in [ticket AD-001](support-tickets/AD-001-hr-password-reset.md).

## Verification method

1. Validate user identity with `whoami`.
2. Attempt directory listing of authorized and all three unauthorized shares.
3. Create and read a harmless text file in the authorized share.
4. Attempt creating a harmless file in **one** unauthorized share.
5. Remove the authorized test file and re-list the directory.
6. Record both allowed and denied behavior rather than inferring access from group membership alone.

## Limits

This is a **four-user representative test**, not an exhaustive 30-user entitlement audit. All 16 user/share directory combinations were tested; for cross-department **writes**, only one unauthorized destination was attempted per user. The shares reside on a domain controller because this is a two-VM training lab, not a recommended production file-server deployment.
