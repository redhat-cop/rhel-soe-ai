---
name: shell_profile
description: Maintains the ansible/roles/shell_profile Ansible role that deploys a shell profile template, as part of the Linux SOE. Use when checking or fixing the system-wide shell profile.
---

# shell_profile

Maintains `ansible/roles/shell_profile/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/shell_profile/defaults/main.yml`:

- Single variable, `shell_profile_file`, unset by default — no-op until a
  template source is provided.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/shell_profile`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- shell_profile`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags shell_profile` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags shell_profile --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags shell_profile
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/shell_profile/<short-desc>`, edit `ansible/roles/shell_profile/`, validate
locally (`--syntax-check`, `ansible-lint roles/shell_profile/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[shell_profile] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but is
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list by default
(`#- shell_profile`) — see the caveat at the top of "What to do" above. It is not
referenced by any of the other playbooks (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, `update_rhel.yml`,
`connect_linux.yml`) either. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
