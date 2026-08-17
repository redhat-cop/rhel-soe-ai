---
name: mount_setup
description: Maintains the ansible/roles/mount_setup Ansible role that enables or disables filesystem mounts (local or NFS/CIFS) via /etc/fstab, as part of the Linux SOE. Use when checking or fixing mount/fstab state.
---

# mount_setup

Maintains `ansible/roles/mount_setup/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/mount_setup/defaults/main.yml`:

- `mount_setup_disable` and `mount_setup_enable` both default empty — no-op
  until set. Entries use `ansible.posix.mount` fields directly (`src`, `path`,
  `state`, `fstype`, `opts`, etc.).
- Installs `nfs-utils`/`cifs-utils` automatically, only if an `mount_setup_enable`
  entry's `fstype` needs them.
- An entry present in both lists is treated as "enable wins" — disable is
  skipped for any path also in `mount_setup_enable`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/mount_setup`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags mount_setup --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags mount_setup
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/mount_setup/<short-desc>`, edit `ansible/roles/mount_setup/`, validate
locally (`--syntax-check`, `ansible-lint roles/mount_setup/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[mount_setup] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags mount_setup ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
