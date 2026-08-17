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
| `accounts_local` | Local (non-domain) user/group create/delete, passwords, sudoers, SSH keys |
| `certificates` | CA trust store (anchors/blocklist/extended-format) via update-ca-trust |
| `dns_cache` | Local DNS caching via dnsmasq/systemd-resolved/nscd — disabled by default |
| `domain_ad` | AD domain join/leave via realmd/adcli + sssd/authselect — no-op until a domain is set |
| `etc_hosts` | Full, exclusive rewrite of `/etc/hosts`; rebuilds initramfs on change |
| `files_acl` | POSIX ACL entries on arbitrary paths — list-driven, empty by default |
| `files_copy` | Copies files/renders templates to arbitrary destinations — empty by default |
| `files_create` | Creates directories/files/symlinks with ownership/mode — empty by default |
| `files_fetch` | Pulls files from managed hosts to the control node — empty by default |
| `files_get` | Downloads files onto managed hosts via URL — empty by default |
| `files_properties` | Sets ownership/mode on existing paths — empty by default |
| `files_remove` | Removes files/dirs by path or glob — **destructive footgun, see its SKILL.md** |
| `files_unarchive` | Extracts archives to a destination — empty by default |
| `firewall` | Basic firewalld enable/zone/ports — explicitly defers to `system_roles.firewall` for more |
| `ima_evm_setup` | IMA/EVM file-integrity appraisal — RHEL 9.7+ only, untouched (`null`) by default |
| `ipv6_setup` | IPv6 enable/disable via sysctl + grubby + NM — **reboots on change, no opt-out flag** |
| `mount_setup` | Mount/unmount via `/etc/fstab` (local, NFS, CIFS) — empty by default |
| `multipath_setup` | device-mapper-multipath config — **reboots by default** (`multipath_setup_reboot: true`) |
| `packages_install` | Baseline dnf package set (distinct from `troubleshooting_tools`'s list) |
| `packages_remove` | dnf package denylist removal — small default list, cross-checked against `packages_install` |
| `packages_verify` | rpm-level package verification (missing/modified files) — audit-only by default |
| `performance_tuning` | Active `tuned` profile — defaults already branch on guest vs. bare metal |
| `repository_setup` | yum.repos.d files + RHSM registration/repo enablement |
| `rescue_image` | Kernel rescue image generation toggle — disabled by default |
| `resolver_configuration` | How `/etc/resolv.conf` is populated (nm/direct/symlink/remove/nothing) |
| `root_password` | Root account password — no-op until `root_password` is set (vault) |
| `scap_compliance` | OpenSCAP oscap scan — **`scap_compliance_remediate` (a role var, not `--check`) gates changes** |
| `scap_satellite` | OpenSCAP scan via Satellite/Capsule-defined policies — reports only, no remediation |
| `sebooleans` | SELinux boolean enable/disable — empty by default |
| `security_hardening` | Secure Boot/FIPS verification (audit-only, can fail run), kernel lockdown, SELinux mode, crypto policy |
| `service_state` | systemd mask/unmask/enable/disable/restart by list — `sshd` is hard-protected |
| `shell_profile` | System-wide shell profile template — unset by default |
| `splunk_forwarder` | Splunk universal forwarder deployment-server + local user config |
| `sshd_configuration` | Declarative sshd_config options, validated with `sshd -t` before applying |
| `system_coredump` | systemd-coredump enable + size cap — disabled by default |
| `system_hostname` | `/etc/hostname` — defaults to the host's own current FQDN fact |
| `timezone` | System timezone via `community.general.timezone` — default `UTC` |
| `watchdog` | systemd hardware/software watchdog timeouts — enabled by default (`60s` runtime only) |

Four more roles exist under `ansible/roles/` but are **not in
`ansible/site.yml`'s default list at all** (tag-invocable only, never run by
an untagged `ansible-playbook ansible/site.yml`), because each acts
unconditionally with no guard variable and/or reboots/auto-updates/
de-registers the host outright:

| Skill / role | Domain | Why excluded from the default run |
|---|---|---|
| `system_init` | Post-install cleanup (reboot + syslog message) | README says explicitly optional, one-time use — not a repeatable baseline check |
| `system_reboot` | Reboots per policy (`never`/`when_needed`/`always`) | Its entire purpose is to reboot the host |
| `system_unregister` | Unregisters from RHSM + Red Hat Insights | Runs **unconditionally**, no guard variable — would de-register every host on every full run |
| `system_update` | `dnf update *` on everything | Runs **unconditionally**, no guard variable — fleet-wide auto-patching needs an explicit decision, not a default |

All 43 of the roles above `accounts_local`…`watchdog`/`timezone`, plus these
four, were bulk-imported from myllynen/rhel-ansible-roles
(`git log -- ansible/roles/<name>`) rather than hand-authored for this repo,
and — unlike the original reference domains — don't add their own
`assert`-based drift checks on top of what their Ansible modules already
report via `--check --diff`.

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
- `ipv6_setup` **reboots on change with no opt-out flag** (unlike
  `boot_parameters`/`system_locale`, there's no `-e` to suppress it).
- `multipath_setup` reboots by default (`multipath_setup_reboot: true`)
  rather than reloading `multipathd` in place.
- `scap_compliance` remediates (not just audits) whenever
  `scap_compliance_remediate: true` is set on the host/group, **regardless
  of whether `--check` is passed** — confirm that variable's value before
  assuming `--check --diff` is safe against it.

`system_init`, `system_reboot`, `system_unregister`, and `system_update`
are not in the roles list at all (see the table above) specifically so a
full `ansible-playbook ansible/site.yml` run can never auto-reboot,
auto-update, or de-register a host as a side effect — invoke each
individually and deliberately with `--tags <name>` only when that specific
action is actually wanted.

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
