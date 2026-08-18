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

**NFS client hosts** — `ansible/nfs_client_setup.yml` sets
`mount_setup_enable` for `nfs_mount_src`/`nfs_mount_dir` and is the normal
way to run this role:

```
ansible-playbook ansible/nfs_client_setup.yml --tags mount_setup --check --diff   # audit
ansible-playbook ansible/nfs_client_setup.yml --tags mount_setup                  # remediate
```

Summarize the diff output and any failed tasks in plain language, and only
drop `--check` after the user explicitly asks.

**Any other host** — the role is present but **commented out** in
`ansible/configure_rhel.yml`'s `roles:` list (`#- mount_setup`); it's a
no-op there today. Uncomment it and set `mount_setup_enable`/
`mount_setup_disable` for that host/group before
`ansible-playbook ansible/configure_rhel.yml --tags mount_setup` will do
anything.

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/mount_setup/<short-desc>`, edit `ansible/roles/mount_setup/`, validate
locally (`--syntax-check`, `ansible-lint roles/mount_setup/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[mount_setup] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table. It's
active by default only via `ansible/nfs_client_setup.yml`; it's present but
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list, so a
plain, untagged `ansible-playbook ansible/configure_rhel.yml` run does not
touch mounts on a general-purpose host. This repo no longer uses
`ansible/site.yml`; see `docs/ARCHITECTURE.md`.
