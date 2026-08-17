---
name: sshd_configuration
description: Maintains the ansible/roles/sshd_configuration Ansible role that manages sshd_config options declaratively, resets config to RPM defaults, and validates every edit with sshd -t before applying, as part of the Linux SOE. Use when checking or fixing SSH daemon configuration.
---

# sshd_configuration

Maintains `ansible/roles/sshd_configuration/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/sshd_configuration/defaults/main.yml`:

- `sshd_options` (dict, default empty) is enabled/updated; if
  `/etc/ssh/sshd_config.d` exists, changes are written exclusively into
  `0-ansible.conf` there rather than editing `sshd_config` directly.
  `ListenAddress` and `Match` blocks are only supported on RHEL 9+.
- `sshd_options_disable` (default empty) comments matching options out of
  every sshd config file found.
- **The role refuses to set `PermitRootLogin: 'no'` when the current
  connection is root without `sudo` (`SUDO_USER` not in the environment)** —
  a built-in guard against locking out the very connection making the change.
- `sshd_configuration_config_reset` (default `false`, RHEL 9+ only) resets
  RPM-provided files to shipped defaults — the role's own note: this can
  cause idempotency issues combined with `sshd_options_disable`, and only
  resets RPM-provided files, not others (suggests `files_copy` for older
  RHEL).
- `sshd_configuration_exclusive` (default `false`) removes unrecognized files
  from `sshd_config.d`, protected by `sshd_configuration_files_known`
  (defaults list several ComplianceAsCode/RHEL-provided filenames).
- Every config write is validated with `sshd -t -f %s` before being applied —
  same pattern as `motd_issue`'s sshd banner edit noted in
  `docs/ARCHITECTURE.md`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/sshd_configuration`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags sshd_configuration --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags sshd_configuration
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/sshd_configuration/<short-desc>`, edit `ansible/roles/sshd_configuration/`, validate
locally (`--syntax-check`, `ansible-lint roles/sshd_configuration/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[sshd_configuration] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This role can lock out remote access if misused despite its guards (e.g.
  disabling password auth with no key-based access configured yet) — always
  review the `--check --diff` output for `PermitRootLogin`/`PasswordAuthentication`-type
  changes with extra care, and confirm out-of-band access exists before
  remediating a remote-only host.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags sshd_configuration ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
