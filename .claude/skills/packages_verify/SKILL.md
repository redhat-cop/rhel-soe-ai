---
name: packages_verify
description: Maintains the ansible/roles/packages_verify Ansible role that runs rpm-level package verification (missing files, modified content) against a chosen package list, as part of the Linux SOE. Use when checking for tampered or incomplete package installations.
---

# packages_verify

Maintains `ansible/roles/packages_verify/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/packages_verify/defaults/main.yml`:

- `packages_verify_enable` (default `false`) — no-op until enabled.
- `packages_verify` (default: `glibc`, `kernel`, `selinux-policy`) — empty list
  means verify all installed packages.
- `packages_verify_check_missing`/`packages_verify_check_content` (both
  default `true`) control whether missing-file and modified-content checks
  run, registering `missing_packages`/`verified_packages` respectively.
- `packages_verify_fail_missing`/`packages_verify_fail_content` (both default
  `false`) control whether a finding fails the role outright (audit-only by
  default) or is only reported.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/packages_verify`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- packages_verify`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags packages_verify` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags packages_verify --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags packages_verify
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/packages_verify/<short-desc>`, edit `ansible/roles/packages_verify/`, validate
locally (`--syntax-check`, `ansible-lint roles/packages_verify/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[packages_verify] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but is
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list by default
(`#- packages_verify`) — see the caveat at the top of "What to do" above. It is not
referenced by any of the other playbooks (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, `update_rhel.yml`,
`connect_linux.yml`) either. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
