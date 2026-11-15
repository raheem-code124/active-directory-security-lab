# Lab notes

## Design decisions

- Original domain runs on isolated VirtualBox internal network `CORP-LAB`; a **disconnected DC01 clone** ran on a separate internal network `CORP-LAB-TEST`.
- Company OUs and departmental security groups separate object organization from access permission grants.
- Independent workstation GPOs handle lock setting, firewall defaults and removable-disk restrictions.
- Both NTFS and share ACLs were inspected; effective SMB allow/deny actions were tested as real signed-in fictional department users.
- Controlled lockout experiments used a dedicated test identity and fine-grained policy. Temporary security test objects were removed.
- The USB restriction was configuration-verified without a physical write attempt; DNS timeout cause remains unresolved.

## Screenshot filenames

**174 screenshots**, all with four-digit numbers: `0001`, `0113`, `0124`, `0132i`. Letter suffixes remain on the same original milestones. Screenshot `0117` was not supplied; no placeholder was invented. Binary image data was not changed by the rename. [Full screenshot index](../documentation/evidence-index.md).

## Sharing and maintenance

- Review screenshots and scripts for passwords, tokens, or personal information before making them publicly accessible.
- Do not commit virtual-machine disks, ISO files, credentials, or private Security log exports.
- After changes, check [GitHub Actions](https://github.com/raheem-code124/active-directory-security-lab/actions) and verify the screenshot links.
- Keep the original 30-user lab results distinct from the 34-account clone tests.
