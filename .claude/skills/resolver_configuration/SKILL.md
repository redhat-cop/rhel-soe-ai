---
name: resolver_configuration
description: Maintains the ansible/roles/resolver_configuration Ansible role that manages how /etc/resolv.conf is populated (via NetworkManager, direct write, symlink, or left alone), as part of the Linux SOE. Use when checking or fixing DNS resolver configuration — pairs with the dns_cache role, e.g. when using systemd-resolved.
---

# resolver_configuration

Maintains `ansible/roles/resolver_configuration/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/resolver_configuration/defaults/main.yml`:

- `resolver_configuration_method` (default `nothing`) selects one of five
  distinct behaviors: `nm` (NetworkManager global overrides),
  `direct` (write `/etc/resolv.conf` directly and stop NM from touching it),
  `symlink` (point `/etc/resolv.conf` at
  `/run/NetworkManager/resolv.conf` — the pairing point with `dns_cache`'s
  `systemd-resolved` option), `remove` (undo this role's own NM
  configuration, leave `/etc/resolv.conf` as-is), or `nothing` (true no-op,
  the default).
- `resolver_nameservers` (must have at least one entry for `nm`/`direct` to be
  meaningful), `resolver_search_domains`, `resolver_options` are all empty by
  default.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/resolver_configuration`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags resolver_configuration --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags resolver_configuration
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/resolver_configuration/<short-desc>`, edit `ansible/roles/resolver_configuration/`, validate
locally (`--syntax-check`, `ansible-lint roles/resolver_configuration/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[resolver_configuration] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags resolver_configuration ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
