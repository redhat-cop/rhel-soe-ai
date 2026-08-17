---
name: files_fetch
description: Maintains the ansible/roles/files_fetch Ansible role that pulls files from managed hosts back to the control node via ansible.builtin.fetch, as part of the Linux SOE. Use when checking or fixing which remote files/directories should be collected centrally.
---

# files_fetch

Maintains `ansible/roles/files_fetch/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/files_fetch/defaults/main.yml`:

This is a low-level, list-driven building block used both directly (a host
sets `files_fetch` in group_vars/host_vars) and indirectly (e.g. `certificates`
includes `files_remove` internally for its exclusive-mode cleanup). Default
is always an empty list — no-op until something sets it.
- The role's own comment warns fetch is very slow with large files when
  combined with `become`. Result registered as `fetch_files`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/files_fetch`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags files_fetch --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags files_fetch
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/files_fetch/<short-desc>`, edit `ansible/roles/files_fetch/`, validate
locally (`--syntax-check`, `ansible-lint roles/files_fetch/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[files_fetch] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags files_fetch ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
