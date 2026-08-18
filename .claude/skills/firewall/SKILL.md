---
name: firewall
description: Maintains the ansible/roles/firewall Ansible role that provides basic firewalld enable/disable, default-zone, and open-ports/services management, as part of the Linux SOE. Use when checking or fixing basic firewall state — for more complete firewall configuration, note the role explicitly defers to system_roles.firewall.
---

# firewall

Maintains `ansible/roles/firewall/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/firewall/defaults/main.yml`:

- `firewall_enable: null` (default) means **leave firewalld's enabled/disabled
  state untouched** — the role only branches into `enable.yml`/`disable.yml`
  when this is explicitly `true`/`false`.
- `firewall_default_zone` (default `public`), `firewall_open_ports`,
  `firewall_open_services` (both default empty) are only applied in the
  enable path.
- `firewall_close_unconfigured` (default `false`) — if `true`, closes any
  port/service not in the two lists above; the `ssh` service is protected
  from closure regardless of this setting.
- The role's own README states this is deliberately basic — recommends
  `system_roles.firewall` (i.e. `redhat.rhel_system_roles.firewall`) for
  anything more complete.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/firewall`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags firewall --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags firewall
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/firewall/<short-desc>`, edit `ansible/roles/firewall/`, validate
locally (`--syntax-check`, `ansible-lint roles/firewall/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[firewall] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `firewall_close_unconfigured: true` can cut off any service not explicitly
  listed — review `firewall_open_ports`/`firewall_open_services` completeness
  before enabling it on a host reachable only over the network being closed.

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
for the general host baseline, and has a row in
`.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of both
`ansible-playbook ansible/configure_rhel.yml --tags firewall ...` and a full,
untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo no longer
uses `ansible/site.yml` as the baseline entrypoint — see `docs/ARCHITECTURE.md`.

The same role is **also** invoked by `ansible/nfs_server_setup.yml`, with its
own purpose-specific variables set directly in that playbook (not this
role's `defaults/main.yml`) — that playbook opens the `nfs` firewalld
service on the export network, not the general baseline's port/service
set. When asked to audit/remediate `firewall` on a host, check whether it's
an NFS server (use `nfs_server_setup.yml`) or a general-purpose host (use
`configure_rhel.yml`) before picking a playbook; running the wrong one
reports drift against the wrong intent.
