# Lab notes and publication checklist

## Design decisions

- Original domain runs on isolated VirtualBox internal network `CORP-LAB`; a **disconnected DC01 clone** ran on a separate internal network `CORP-LAB-TEST`.
- Company OUs and departmental security groups separate object organization from access permission grants.
- Independent workstation GPOs handle lock setting, firewall defaults and removable-disk restrictions.
- Both NTFS and share ACLs were inspected; effective SMB allow/deny actions were tested as real signed-in fictional department users.
- Controlled lockout experiments used a dedicated test identity and fine-grained policy. Temporary security test objects were removed.
- The USB restriction was configuration-verified without a physical write attempt; DNS timeout cause remains unresolved.

## Screenshot filenames

**174 screenshots**, all with four-digit numbers: `0001`, `0113`, `0124`, `0132i`. Letter suffixes remain on the same original milestones. Screenshot `0117` was not supplied; no placeholder was invented. Binary image data was not changed by the rename. [Full screenshot index](../documentation/evidence-index.md).

## Publication and privacy checklist

- [ ] Inspect every screenshot visually for passwords, keys, tokens, personal identifying details and unrelated programs/windows.
- [ ] Inspect PowerShell scripts and historical CSV data before publication. Do not commit VM disks, ISO files, passwords or private log exports.
- [ ] Verify live screenshot links, markdown links, the architecture image and the current CI run.
- [ ] Confirm original 30-user directory and isolated clone-only 34-account state are never conflated.
- [ ] Keep the GitHub repository **private** until the privacy review is complete.
