---
name: system_init
description: Maintains the ansible/roles/system_init Ansible role that performs optional post-install cleanup actions (reboot and/or syslog message), as part of the Linux SOE. Use when asked about post-installation initialization steps — the role's own README states it is by no means mandatory.
---

# system_init

Maintains `ansible/roles/system_init/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_init/defaults/main.yml`:

- `system_init_final_actions` (default: `[reboot, syslog]`) — `localhost`
  is excluded from the reboot action regardless of this list (per the role's
  own default comment).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_init`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_init --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_init
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_init/<short-desc>`, edit `ansible/roles/system_init/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_init/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_init] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Because `reboot` is in the default action list, running this role for the
  first time on a host reboots it — confirm before including it in a
  remediate run, same as any other reboot-by-default role in this repo
  (`boot_parameters`... no, `boot_parameters` is audit-only; think
  `system_locale`, `ipv6_setup`, `multipath_setup`).

## Wiring into the SOE

This role is deliberately **excluded** from `ansible/site.yml`'s default
`roles:` list (see the comment above that list, and the "excluded from the
default run" table in `.claude/skills/soe/SKILL.md`) because it acts
unconditionally with no guard variable and/or reboots, auto-updates, or
de-registers the host outright. It only runs when explicitly invoked with
`--tags system_init`, as shown above — never as a side effect of a full SOE
run. Don't add it back to `ansible/site.yml`'s default list without an
explicit decision from a human operator; that would be a cross-cutting,
high-blast-radius change in its own right.
