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

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags files_get --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags files_get
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

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags files_get ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
