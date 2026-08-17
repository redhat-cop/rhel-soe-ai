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
| `accounts_policy` | Local account/login/PAM/authselect config (deploys config files; no built-in drift assertions) |
| `audit_setup` | auditd install + config/rules deployment; can fail or reboot on locked-rules conflicts |
| `boot_parameters` | GRUB/kernel command-line via grubby — **remediates and can reboot by default**, not audit-only |
| `cron_setup` | cron service, cron.allow/cron.deny, and declarative crontab entries |
| `guest_agent` | Guest agent for the detected hypervisor (role dir is `guest_agent`, not `vm_guest_agent`) |
| `motd_issue` | `/etc/motd(.d)` and `/etc/issue.d`/`/etc/issue.net` banners — does not manage the sshd banner |
| `system_keyboard` | Virtual console keymap + font (no X11 handling) |
| `system_locale` | System locale — restricted to `C.UTF-8`/`en_US.UTF-8`/`auto`, **reboots by default** on change |
| `timesync` | Thin wrapper around the external `redhat.rhel_system_roles.timesync` collection role |
| `troubleshooting_tools` | Baseline troubleshooting package set + optional PCP metrics |
| `usbguard_setup` | USBGuard device authorization — **service enablement is NOT opt-in**, on by default with `policy: reject` |

There is no `timezone` role in this repository — only `timesync` (NTP sync
health), which does not manage the system timezone setting itself. If the
user asks about timezone specifically, say so rather than assuming
`timesync` covers it, and treat adding a `timezone` role as a "new domain"
proposal (see below).

## What to do

**To audit the whole SOE** (read-only, safe):

```
ansible-playbook ansible/site.yml --check --diff
```

Summarize per-role: which roles reported no diff (compliant vs. their
current variable settings — note several roles, e.g. `accounts_policy`
and `motd_issue`, do nothing at all until their template/content
variables are set), which showed diffs (drift found, not yet applied),
and which failed a task outright.

**To audit one domain**: add `--tags <domain>`, e.g.
`ansible-playbook ansible/site.yml --tags timesync --check --diff`.

**To remediate**: never run the full playbook without `--check` across all
domains unless the user has explicitly asked to apply fixes fleet-wide —
this touches auth, boot config, and device policy in one pass (high blast
radius), and at least two of these roles can act immediately and
disruptively on their own:

- `usbguard_setup` enables and starts enforcement **by default**
  (`policy: reject`, no opt-in flag) — see that skill's `SKILL.md` before
  remediating any host with only physical console access.
- `boot_parameters` and `system_locale` both **reboot the host by
  default** (`boot_parameters_reboot` / `system_locale_reboot`) when they
  change something — get explicit confirmation before a real remediate
  run, or pass `-e boot_parameters_reboot=false -e system_locale_reboot=false`
  if the user wants changes applied without an immediate reboot.
- `audit_setup` can also reboot the host if
  `audit_setup_update_lock: reboot` is set and the current rules are
  locked.

Prefer remediating one domain at a time
(`ansible-playbook ansible/site.yml --tags <domain>`) with the user's
confirmation of what will change, per `docs/ARCHITECTURE.md`.

**To target real hosts**: add them to `ansible/inventory/hosts.ini` (or
pass `-i <path>`); the playbook defaults to `hosts: all` with
`become: true`.

**To propose a change spanning multiple roles or `ansible/site.yml`
itself**: this is the one case that doesn't belong to a single domain
skill. Same rules as every domain's "propose a change" workflow apply —
never commit directly, branch as `soe/<short-desc>` (no domain prefix,
since it's cross-cutting), validate locally, push, open a PR titled
`[soe] <what changed>`, then stop for human review. Don't fold a
cross-cutting change into a single domain's PR — see
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Adding a domain

Follow "Adding a new domain skill" in `docs/ARCHITECTURE.md`, then add a
row to the table above.
