---
name: soe
description: Orchestrates all Linux Standard Operating Environment domain roles (ansible/site.yml) to audit or remediate a RHEL-family host, and summarizes the results. Use when asked to check, audit, or bring a system into compliance with "the SOE" or "the standard operating environment" as a whole, rather than a single domain.
---

# soe

Top-level orchestrator for the domain skills, each of which maintains one
Ansible role under `ansible/roles/`. This skill runs `ansible/site.yml`
(directly, or filtered by `--tags`) and summarizes the result. See
`docs/ARCHITECTURE.md` for the shared conventions these roles follow.

## Domain roles

| Skill / role | Domain |
|---|---|
| `accounts_policy` | Local account/password policy |
| `audit_setup` | auditd configuration and rules |
| `boot_parameters` | GRUB/kernel command line baseline (audit-only) |
| `cron_setup` | cron service and access control |
| `vm_guest_agent` | Guest agent for the detected hypervisor |
| `motd_issue` | `/etc/motd` and `/etc/issue*` banners |
| `system_keyboard` | Console/X11 keyboard layout |
| `system_locale` | System locale (`LANG`, etc.) |
| `timesync` | NTP/chrony time synchronization |
| `timezone` | System timezone |
| `troubleshooting_tools` | Baseline troubleshooting package set |
| `usbguard_setup` | USBGuard device authorization policy (service enablement is opt-in) |

## What to do

**To audit the whole SOE** (read-only, safe):

```
ansible-playbook ansible/site.yml --check --diff
```

Summarize per-role: which roles reported no diff/no failed asserts
(compliant), which showed diffs (drift found, not yet applied), and which
failed an `assert` (a check that can't be auto-fixed — read the `fail_msg`).

**To audit one domain**: add `--tags <domain>`, e.g.
`ansible-playbook ansible/site.yml --tags timesync --check --diff`.

**To remediate**: never run the full playbook without `--check` across all
domains unless the user has explicitly asked to apply fixes fleet-wide —
this touches auth, boot config, and device policy in one pass (high blast
radius). Prefer remediating one domain at a time
(`ansible-playbook ansible/site.yml --tags <domain>`) with the user's
confirmation of what will change, per `docs/ARCHITECTURE.md`. Two roles
need extra care even then:

- `usbguard_setup` only enables the service when
  `soe_usbguard_manage_service: true` is set — leave this off unless the
  user has reviewed `/etc/usbguard/rules.conf` on the target host.
- `boot_parameters` is audit-only; there is no remediate step to run — a
  failed assert there needs a manual, reviewed GRUB edit and a reboot.

**To target real hosts**: add them to `ansible/inventory/hosts.ini` (or
pass `-i <path>`); the playbook defaults to `hosts: all` with
`become: true`.

**To propose a change spanning multiple roles or `ansible/site.yml`
itself** (e.g. adding a new domain, changing execution order): this is the
one case that doesn't belong to a single domain skill. Same rules as every
domain's "propose a change" workflow apply — never commit directly, branch
as `soe/<short-desc>` (no domain prefix, since it's cross-cutting), validate
locally, push, open a PR titled `[soe] <what changed>`, then stop for human
review. Don't fold a cross-cutting change into a single domain's PR — see
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Adding a domain

Follow "Adding a new domain skill" in `docs/ARCHITECTURE.md`, then add a
row to the table above.
