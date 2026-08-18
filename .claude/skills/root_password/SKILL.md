---
name: root_password
description: Maintains the ansible/roles/root_password Ansible role that sets the root account password, as part of the Linux SOE. Use when checking or fixing the root password.
---

# root_password

Maintains `ansible/roles/root_password/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

`ansible/roles/root_password/README.md` documents this role's full
configuration surface (every `defaults/main.yml` variable, with its
original inline comments, rendered as a single reference). Read it
before proposing or explaining how to configure this role — it
reflects the role's actual current defaults even if a variable summary
elsewhere in this file has drifted out of sync with the role.

## What the role actually does

Encoded in `ansible/roles/root_password/defaults/main.yml`:

- No-ops unless `root_password` is set (unset by default — commented out,
  expected from vault).
- `root_password_encrypted` (default `true`) controls whether the value is
  treated as already-hashed or hashed in-role using a salt derived from
  `root_password_salt_seed` (default `{{ inventory_hostname }}`) — same
  pattern as `accounts_local`.
- The task itself always sets `no_log: true` (not tied to a variable, unlike
  `accounts_local_no_log`).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/root_password`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags root_password --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags root_password
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/root_password/<short-desc>`, edit `ansible/roles/root_password/`, validate
locally (`--syntax-check`, `ansible-lint roles/root_password/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[root_password] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This is one of the highest-blast-radius single tasks in the repo — a wrong
  or accidentally-shared root password affects every account on the host.
  Never put `root_password` in plaintext in a PR body, `-e`, or `--check --diff`
  output (the value itself won't appear in `--diff` since the task is
  `no_log`, but don't undermine that by echoing the source vault value
  elsewhere).

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as
part of both `ansible-playbook ansible/configure_rhel.yml --tags root_password ...` and
a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
