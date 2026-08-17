---
name: system_coredump
description: Maintains the ansible/roles/system_coredump Ansible role that enables/disables systemd-coredump and sets its size cap, as part of the Linux SOE. Use when checking or fixing system-wide coredump behavior.
---

# system_coredump

Maintains `ansible/roles/system_coredump/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_coredump/defaults/main.yml`:

- `system_coredump_enable` (default `false`) and
  `system_coredump_process_size_max` (default `4G`, i.e. `ProcessSizeMax`).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_coredump`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_coredump --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_coredump
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_coredump/<short-desc>`, edit `ansible/roles/system_coredump/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_coredump/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_coredump] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags system_coredump ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
