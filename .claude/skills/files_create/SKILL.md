---
name: files_create
description: Maintains the ansible/roles/files_create Ansible role that creates directories, empty files, and symlinks with specified ownership/mode via ansible.builtin.file, as part of the Linux SOE. Use when checking or fixing the existence/permissions of specific paths.
---

# files_create

Maintains `ansible/roles/files_create/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/files_create/defaults/main.yml`:

This is a low-level, list-driven building block used both directly (a host
sets `files_create` in group_vars/host_vars) and indirectly (e.g. `certificates`
includes `files_remove` internally for its exclusive-mode cleanup). Default
is always an empty list — no-op until something sets it.
- Each entry's `state` (`directory`/`file`/`link`) determines which of three
  registered result variables it contributes to: `create_directories`,
  `create_files`, `create_links`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/files_create`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags files_create --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags files_create
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/files_create/<short-desc>`, edit `ansible/roles/files_create/`, validate
locally (`--syntax-check`, `ansible-lint roles/files_create/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[files_create] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags files_create ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
