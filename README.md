# Enterprise Active Directory Security & Administration Lab

> **Status:** In progress — environment setup and validation have not yet been completed.

## Project overview

This is a hands-on, isolated Windows enterprise lab designed to develop practical skills in Windows Server administration, Active Directory, identity and access management, endpoint security, PowerShell, and IT troubleshooting.

The environment represents a fictional organization. Any incidents and security misconfigurations will be simulated within systems controlled for this project.

## Planned environment

| Component | Planned use |
|---|---|
| Oracle VirtualBox | Run and isolate the lab virtual machines |
| Windows Server 2025 evaluation (`DC01`) | Active Directory Domain Services, DNS, Group Policy, and selected network services |
| Windows 11 evaluation (`CLIENT01`) | Domain-joined endpoint for authentication, policy, and access-control testing |
| PowerShell | Administration, verification, and account onboarding automation |

**Network safety:** Lab domain services will use a dedicated isolated virtual network. We will verify network settings before turning on DHCP or promoting a domain controller. No lab passwords or private keys will be published.

## Planned objectives

- [ ] Build and document an isolated Windows Server and Windows client environment
- [ ] Install and configure Active Directory Domain Services and DNS
- [ ] Join a Windows workstation to the lab domain
- [ ] Create organizational units, test users, and security groups
- [ ] Automate selected administrative tasks with PowerShell
- [ ] Configure and verify Group Policy security settings
- [ ] Implement role-based shared-folder and NTFS access controls
- [ ] Configure and troubleshoot controlled DHCP services
- [ ] Audit security-relevant Windows events and apply system hardening
- [ ] Simulate, diagnose, and resolve realistic IT and security issues
- [ ] Publish verified evidence, architecture diagrams, and case studies

## Repository structure

```text
active-directory-security-lab/
├── README.md             # Project overview and progress
├── .gitignore            # Excludes VM images and sensitive files
├── configs/              # Sanitized configuration exports
├── diagrams/             # Architecture and network diagrams
├── documentation/        # Final walkthrough and incident reports
├── notes/                # Sanitized lab notes
├── screenshots/          # Verified screenshots, added after testing
└── scripts/              # PowerShell administration and validation scripts
```

## Documentation approach

Configuration steps, command outputs, tests, and screenshots will be captured locally during the build. Full technical documentation will be added after the hands-on work has been completed and verified.

**Current stage:** Preparing the virtual environment. No implementation or testing results are claimed yet.

## Scope and safeguards

This is a personal educational lab, not a production deployment. All test accounts and security experiments are confined to the owned virtual environment. Large installation media, VM disks, credentials, and sensitive raw logs are intentionally excluded from version control.
