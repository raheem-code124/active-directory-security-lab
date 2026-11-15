# Notes: decisions, troubleshooting, and review items

## Design decisions

1. **Lab isolation:** VirtualBox `CORP-LAB` keeps a test DHCP/DNS service off physical networks.
2. **Separate AD OUs and security groups:** OUs organize objects and target GPOs; groups grant folder access.
3. **Dedicated GPOs:** Workstation inactivity lock, firewall, USB restrictions, and DC auditing are separate for easier scope management.
4. **Two-layer SMB authorization:** Use both share permissions and NTFS permissions.
5. **Dedicated lockout test:** Use `lockout.test` with a fine-grained password policy to avoid editing the global domain lockout setting.
6. **Reversible exercises:** Delete `audit.test`, `SG_Audit_Test`, `lockout.test` and `PSO-Lockout-Test` after collecting evidence.
7. **Documentation honesty:** Don't claim an untested physical USB write block, full DNS timeout remediation, or original on-VM file hashes not yet independently compared against archived sources.

## Screenshot naming

Capture numbers `01–88` describe ordered lab milestones. Suffixes (`10a`, `10b`, `52a`–`52d`, `80a`–`80c`, `84a`–`84b`) represent multiple screenshots for one milestone. Thus there are **107 images**, not just 88.

## Review checklist

- [ ] Verify main README renders the `diagrams/architecture.svg` preview.
- [ ] Check that each evidence link opens the intended screenshot.
- [ ] Confirm the host, domain, OU, group names and machine IPs against the screenshots.
- [ ] Open the DNS report and confirm it does not claim every timeout resolved.
- [ ] Confirm phase reports distinguish observed tests from planned or example commands.
- [ ] Inspect screen captures for credential/private-data leaks before making this repository public.
- [ ] Do **not** publish VM disks, ISO images, login passwords, event-log dumps, or secret exports.
- [ ] Review new `scripts/` helpers before running them; they were not part of original lab execution.
- [ ] Make the currently private repository public only after auditing screenshots for sensitive content.

## Publication notes

This repository documents a completed **hands-on simulated lab**. It contains no external production systems, real client/customer incidents, or third-party employee directory. The screenshots and reports should support each claim; when an action was not demonstrated, the report says so.
