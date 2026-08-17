---
name: watchdog
description: Maintains the ansible/roles/watchdog Ansible role that configures the systemd hardware/software watchdog (runtime/reboot/kexec timeouts and device), as part of the Linux SOE. Use when checking or fixing systemd watchdog configuration.
---

# watchdog

Maintains `ansible/roles/watchdog/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/watchdog/defaults/main.yml`:

- `watchdog_enable` (default `true`) branches into `enable.yml`/`disable.yml`.
- `watchdog_runtime_sec` (default `60s`) is the only timeout set by default;
  `watchdog_reboot_sec`, `watchdog_kexec_sec`, `watchdog_device` are unset.
- Configuration file location is version-dependent: RHEL 10+ writes a drop-in
  at `/etc/systemd/system.conf.d/95-ansible.conf`; earlier releases edit
  `/etc/systemd/system.conf` directly.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/watchdog`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags watchdog --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags watchdog
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/watchdog/<short-desc>`, edit `ansible/roles/watchdog/`, validate
locally (`--syntax-check`, `ansible-lint roles/watchdog/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[watchdog] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included (active, uncommented) in `ansible/configure_rhel.yml`'s
`roles:` list and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so
it runs as part of both `ansible-playbook ansible/configure_rhel.yml --tags watchdog ...`
and a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
