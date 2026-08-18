---
name: dns_cache
description: Maintains the ansible/roles/dns_cache Ansible role that enables or disables local DNS caching via dnsmasq, systemd-resolved, or nscd, as part of the Linux SOE. Use when checking or fixing DNS caching configuration.
---

# dns_cache

Maintains `ansible/roles/dns_cache/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/dns_cache/defaults/main.yml`:

- `dns_cache_enable` defaults `false` — the role always runs a disable pass
  first (`disable.yml`), then, only if enabled, includes exactly one of
  `dnsmasq.yml` / `nscd.yml` / `systemd_resolved.yml` based on
  `dns_cache_component` (default `systemd-resolved`, recommended on RHEL 10+;
  `dnsmasq` recommended on RHEL 9 and earlier per the role's own comment).
  `nscd` is not available on RHEL 10+.
- `dns_cache_dnsmasq_ttl` (default `10`) and `dns_cache_dnsmasq_local_domain`
  only apply to the dnsmasq path.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/dns_cache`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- dns_cache`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags dns_cache` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags dns_cache --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags dns_cache
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/dns_cache/<short-desc>`, edit `ansible/roles/dns_cache/`, validate
locally (`--syntax-check`, `ansible-lint roles/dns_cache/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[dns_cache] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- The role's own comment notes `/etc/resolv.conf` correctness should be checked
  before/after — pair with `resolver_configuration` as needed; this role does
  not manage `/etc/resolv.conf` itself.

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but is
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list by default
(`#- dns_cache`) — see the caveat at the top of "What to do" above. It is not
referenced by any of the other playbooks (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, `update_rhel.yml`,
`connect_linux.yml`) either. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
