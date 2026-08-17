---
name: files_get
description: Maintains the ansible/roles/files_get Ansible role that downloads files onto managed hosts over the network via ansible.builtin.get_url, as part of the Linux SOE. Use when checking or fixing files that should be present via URL download.
---

# files_get

Maintains `ansible/roles/files_get/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/files_get/defaults/main.yml`:

This is a low-level, list-driven building block used both directly (a host
sets `files_get` in group_vars/host_vars) and indirectly (e.g. `certificates`
includes `files_remove` internally for its exclusive-mode cleanup). Default
is always an empty list — no-op until something sets it.
- Entries map onto `get_url` parameters directly (`url`, `url_username`,
  `url_password`, `validate_certs`, `use_proxy`, `timeout`, `dest`, `mode`).
  `files_get_no_log` (default `true`) suppresses credential values in output
  when a `url_username`/`url_password` is set. Result registered as
  `get_files`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/files_get`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

This role is **not referenced by any playbook in `ansible/`** right now —
not `configure_rhel.yml` (not even commented out), not
`load_balancer_setup.yml`/`nfs_client_setup.yml`/`nfs_server_setup.yml`/
`update_rhel.yml`. There is currently no `ansible-playbook` command that will
invoke `files_get` in this repo. Before running it, either:

1. **Add it to an existing playbook** — most often
   `ansible/configure_rhel.yml`'s `roles:` list (uncomment-style, with a
   `vars:` entry for `files_get` set to what's actually needed), if what's wanted is
   a permanent, repeatable part of the host baseline; or
2. **Write a small ad hoc playbook** for the one-off task, same shape as
   `ansible/load_balancer_setup.yml`/`ansible/nfs_client_setup.yml` (a
   `vars:` block plus a `roles: [files_get]` list), if it's a one-time or
   host-class-specific job that doesn't belong in the general baseline.

Either way, propose it via the branch + PR workflow below rather than running
an untracked local playbook against a real host. Once wired in, audit/remediate
the same way as any other role — `--tags files_get` against whichever playbook now
contains it, `--check --diff` first:

```
ansible-playbook ansible/<playbook>.yml --tags files_get --check --diff   # audit
ansible-playbook ansible/<playbook>.yml --tags files_get                  # remediate
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/files_get/<short-desc>`, edit `ansible/roles/files_get/`, validate
locally (`--syntax-check`, `ansible-lint roles/files_get/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[files_get] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `validate_certs: false` (shown as an example in defaults, not a default
  itself) disables TLS verification for that download — flag this explicitly
  if a proposed entry sets it, since it defeats the point of fetching over
  HTTPS.

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but (see
"What to do" above) is not currently included in any playbook in this repo —
neither the general baseline (`ansible/configure_rhel.yml`) nor any of the
composite playbooks. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
