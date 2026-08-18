---
name: certificates
description: Maintains the ansible/roles/certificates Ansible role that manages the system CA trust store (anchors, blocklist, extended-format files) via update-ca-trust, as part of the Linux SOE. Use when checking or fixing trusted/blocked CA certificates.
---

# certificates

Maintains `ansible/roles/certificates/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/certificates/defaults/main.yml`:

- Copies `certificates_files_anchors` into `/etc/pki/ca-trust/source/anchors/`,
  `certificates_files_blocklist` into `.../blocklist/` (or `.../blacklist/` on
  RHEL < 9), and `certificates_files_ext_format` into `.../source/`. All three
  lists default empty.
- `certificates_files_known` (default: the Satellite/Katello CA path) lists
  extra files that are protected from removal even when `certificates_exclusive`
  is set.
- Runs `update-ca-trust extract` only when a copy task actually changed
  something (or after an exclusive-mode removal).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/certificates`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags certificates --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags certificates
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/certificates/<short-desc>`, edit `ansible/roles/certificates/`, validate
locally (`--syntax-check`, `ansible-lint roles/certificates/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[certificates] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `certificates_exclusive: true` removes any anchor/blocklist/source file not
  in the role's own copied set or in `certificates_files_known` (via the
  `files_remove` role) — review the resulting file list carefully before
  enabling this on a host with certs installed by other means.

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as
part of both `ansible-playbook ansible/configure_rhel.yml --tags certificates ...` and
a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
