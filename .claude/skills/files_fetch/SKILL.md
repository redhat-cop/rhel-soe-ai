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

This role is **not referenced by any playbook in `ansible/`** right now —
not `configure_rhel.yml` (not even commented out), not
`load_balancer_setup.yml`/`nfs_client_setup.yml`/`nfs_server_setup.yml`/
`update_rhel.yml`. There is currently no `ansible-playbook` command that will
invoke `files_fetch` in this repo. Before running it, either:

1. **Add it to an existing playbook** — most often
   `ansible/configure_rhel.yml`'s `roles:` list (uncomment-style, with a
   `vars:` entry for `files_fetch` set to what's actually needed), if what's wanted is
   a permanent, repeatable part of the host baseline; or
2. **Write a small ad hoc playbook** for the one-off task, same shape as
   `ansible/load_balancer_setup.yml`/`ansible/nfs_client_setup.yml` (a
   `vars:` block plus a `roles: [files_fetch]` list), if it's a one-time or
   host-class-specific job that doesn't belong in the general baseline.

Either way, propose it via the branch + PR workflow below rather than running
an untracked local playbook against a real host. Once wired in, audit/remediate
the same way as any other role — `--tags files_fetch` against whichever playbook now
contains it, `--check --diff` first:

```
ansible-playbook ansible/<playbook>.yml --tags files_fetch --check --diff   # audit
ansible-playbook ansible/<playbook>.yml --tags files_fetch                  # remediate
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/files_fetch/<short-desc>`, edit `ansible/roles/files_fetch/`, validate
locally (`--syntax-check`, `ansible-lint roles/files_fetch/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[files_fetch] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but (see
"What to do" above) is not currently included in any playbook in this repo —
neither the general baseline (`ansible/configure_rhel.yml`) nor any of the
composite playbooks. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
