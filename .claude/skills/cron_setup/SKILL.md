---
name: cron_setup
description: Maintains the ansible/roles/cron_setup Ansible role that audits and remediates cron service configuration and access control on RHEL-family systems as part of the Linux SOE. Use when checking or hardening crond, cron.allow/cron.deny, or scheduled task permissions.
---

# cron_setup

Maintains `ansible/roles/cron_setup/`. See `docs/ARCHITECTURE.md` for the
shared conventions.

## Baseline

Encoded in `ansible/roles/cron_setup/defaults/main.yml`:

- `cronie` package installed; `crond.service` enabled and active.
- `/etc/cron.allow` exists (mode `0600`) listing only approved users
  (`soe_cron_allowed_users`, default `[root]`); `/etc/cron.deny` does not
  exist — an explicit allow-list, not a deny-list.
- No group/world-writable paths under `/etc/cron.d`, `/etc/crontab`,
  `/etc/cron.{hourly,daily,weekly,monthly}`.

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags cron_setup --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/cron_setup/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/cron_setup/`,
`--check --diff`), push, and open a PR titled `[cron_setup] <what changed>`
with the `--check --diff` output in the body — then stop for human review.
See `docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- The world-writable-path check filters to paths that actually exist on
  the host before running `find` — `find` errors hard on a missing path
  argument, and not every one of these standard directories is guaranteed
  present on a minimal install.
- This role fixes *permissions*, never removes a cron job — deleting a
  scheduled task is a behavior change that needs its own confirmation from
  the user, separate from a permissions fix.
