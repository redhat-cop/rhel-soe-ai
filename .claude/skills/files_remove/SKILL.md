---
name: files_remove
description: Maintains the ansible/roles/files_remove Ansible role that removes files/directories by exact path or shell glob, as part of the Linux SOE. Use when checking or fixing which files/directories should be absent — including internally by other roles such as certificates for exclusive-mode cleanup.
---

# files_remove

Maintains `ansible/roles/files_remove/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/files_remove/defaults/main.yml`:

This is a low-level, list-driven building block used both directly (a host
sets `files_remove` in group_vars/host_vars) and indirectly (e.g. `certificates`
includes `files_remove` internally for its exclusive-mode cleanup). Default
is always an empty list — no-op until something sets it.
- Supports globbing on the last path element; directories are removed
  recursively. `files_remove_recursive` (default `false`) additionally does a
  recursive `find` for the given patterns — the role's own comment warns this
  makes a pattern like `/etc/*.old` also match `/etc/x/y.old`.
  `files_remove_exclude` protects specific paths from a glob/recursive match.
  Result registered as `remove_files`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/files_remove`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags files_remove --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags files_remove
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/files_remove/<short-desc>`, edit `ansible/roles/files_remove/`, validate
locally (`--syntax-check`, `ansible-lint roles/files_remove/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[files_remove] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- The role's own defaults file carries an explicit warning: a typo or
  unexpected glob expansion here can remove unintended files/directories
  across every managed host with no confirmation prompt. Always review the
  literal expanded pattern (not just the pattern string) in the
  `--check --diff` output before remediating, and be especially careful with
  `files_remove_recursive: true`.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags files_remove ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
