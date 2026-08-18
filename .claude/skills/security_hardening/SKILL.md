---
name: security_hardening
description: Maintains the ansible/roles/security_hardening Ansible role that verifies Secure Boot/FIPS state, sets kernel lockdown mode, SELinux mode, the system crypto policy, and SCP protocol availability, as part of the Linux SOE. Use when checking or fixing these platform-level security settings.
---

# security_hardening

Maintains `ansible/roles/security_hardening/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/security_hardening/defaults/main.yml`:

- `secure_boot_verify`/`fips_mode_verify` (both default `false`) are
  audit-only checks — when enabled, the role **fails** the run if Secure Boot
  or FIPS isn't actually enabled on the host (via `mokutil --sb-state` and
  `/proc/sys/crypto/fips_enabled`/CPU AES flag respectively); it does not
  attempt to turn either on.
- `kernel_lockdown` (default `disabled`; RHEL 9+ only) — the role's own note:
  enabling lockdown (`integrity`/`confidentiality`) prevents using kdump.
- `selinux` (default `enforcing`) and `crypto_policy` (default `DEFAULT`) are
  applied directly.
- `scp_protocol_enable` (default `true`) toggles the (legacy) `scp` protocol,
  distinct from the `scp(1)` command itself per the role's own default
  comment.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/security_hardening`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags security_hardening --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags security_hardening
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/security_hardening/<short-desc>`, edit `ansible/roles/security_hardening/`, validate
locally (`--syntax-check`, `ansible-lint roles/security_hardening/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[security_hardening] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `fips_mode_verify: true` failing does not mean this role can fix it — FIPS
  mode is generally an install-time decision on RHEL; treat a failure here as
  a finding to report, not something to auto-remediate.
  Changing `kernel_lockdown` or `crypto_policy` can affect boot behavior and
  what crypto/kdump features work — treat proposed changes here with the same
  care as `boot_parameters`.

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as
part of both `ansible-playbook ansible/configure_rhel.yml --tags security_hardening ...` and
a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
