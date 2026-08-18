---
name: etc_hosts
description: Maintains the ansible/roles/etc_hosts Ansible role that fully manages /etc/hosts content (header, self-entry, static entries) and rebuilds initramfs on change, as part of the Linux SOE. Use when checking or fixing /etc/hosts entries.
---

# etc_hosts

Maintains `ansible/roles/etc_hosts/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/etc_hosts/defaults/main.yml`:

- Rewrites the entire file: `etc_hosts_header` (default: standard
  Fedora/upstream loopback block) + an optional self-entry
  (`etc_hosts_self_add`, default `true`, built from Ansible network facts) +
  `etc_hosts_entries` (default empty). Anything not produced by these three
  inputs is dropped — this is an exclusive rewrite, not an append.
- `etc_hosts_self_domain` overrides `ansible_facts.domain` for the self-entry;
  the role **fails** if `etc_hosts_self_add` is true and no domain is available
  from either source.
- `etc_hosts_omit_entries` (`none`/`ipv4`/`ipv6`) filters entries by address
  family across header, self-entry, and static entries alike.
- Runs `dracut -f --regenerate-all` whenever the file changes (some initramfs
  configurations embed `/etc/hosts`).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/etc_hosts`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags etc_hosts --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags etc_hosts
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/etc_hosts/<short-desc>`, edit `ansible/roles/etc_hosts/`, validate
locally (`--syntax-check`, `ansible-lint roles/etc_hosts/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[etc_hosts] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Because this is a full rewrite, any entry added outside this role's
  variables (manually, or by another tool) will be silently removed on the
  next run — check `etc_hosts_entries` covers everything the host actually
  needs before remediating.
- The `dracut -f --regenerate-all` on every content change is not
  free — factor that into how often this role runs on a given host.

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as
part of both `ansible-playbook ansible/configure_rhel.yml --tags etc_hosts ...` and
a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
