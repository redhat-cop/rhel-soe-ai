---
name: cron_setup
description: Maintains the ansible/roles/cron_setup Ansible role that installs cronie, manages /etc/cron.allow and /etc/cron.deny, and declaratively manages crontab entries via ansible.builtin.cron on RHEL-family systems as part of the Linux SOE. Use when checking or changing crond, cron.allow/cron.deny, or scheduled cron jobs.
---

# cron_setup

Maintains `ansible/roles/cron_setup/`. See `docs/ARCHITECTURE.md` for the
shared conventions.

## What the role actually does

Encoded in `ansible/roles/cron_setup/defaults/main.yml`:

- Installs `cronie`; enables and starts `crond.service`.
- `cron_setup_allow_file` (default `[]`, i.e. present but empty — meaning
  *no* user can use cron): a list of usernames written one-per-line to
  `/etc/cron.allow` (mode `0600`). Setting it to `null`/`~` **removes**
  `/etc/cron.allow` entirely (falls back to whatever the system default
  allows).
- `cron_setup_deny_file` (default `null`, i.e. removed): same pattern for
  `/etc/cron.deny`.
- `cron_setup_entries` (default unset/empty): a list of crontab entries
  applied via `ansible.builtin.cron`, one `present`/`absent` op per entry
  — supports `name`, `user`, `job`, `special_time`, `minute`/`hour`/etc.,
  `env`, `cron_file`, and `state: absent` to remove a previously-managed
  entry.

## What to do

> **This role is off by default** in `ansible/configure_rhel.yml` — every
> role there (active or not) is gated by a single `configure_rhel_domains`
> list variable (`when: "'<name>' in configure_rhel_domains"`), and `cron_setup`
> isn't in the default value of that list. Nothing needs editing in the
> playbook itself to turn it on: pass the *full* desired domain list via
> `-e`, e.g.
> `-e '{"configure_rhel_domains": [...the default 20..., "cron_setup"]}'`
> (see `.claude/skills/configure_rhel/SKILL.md` for the current default list
> to extend, and why it has to be the full list, not just the addition —
> `-e` replaces the variable's value, it doesn't merge into it). `--tags cron_setup`
> alone is **not** enough — the domains list and `--tags`/`--skip-tags` are
> separate, ANDed gates, both verified independently: a role only runs if
> it's in `configure_rhel_domains` *and* matches the requested tags. Some
> roles (this one — check its `defaults/main.yml` and task file) also have
> their own internal enable flag or required variable on top of that, which
> still needs setting the same as before. Flag all of this to the user before
> assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags cron_setup --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval. Note the **default `cron_setup_allow_file: []`** — running
remediate with defaults on a host that currently has no `/etc/cron.allow`
will create an empty one, which locks out *all* non-root cron use (only
`root` can still use cron via `/etc/crontab` and `/etc/cron.d`, since
those aren't gated by `cron.allow`). Confirm the intended allow-list with
the user before remediating, don't assume `[]` is a safe default to apply
blindly.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/cron_setup/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/cron_setup/`,
`--check --diff`), push, and open a PR titled `[cron_setup] <what changed>`
with the `--check --diff` output in the body — then stop for human review.
See `docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- This role has no permission/ownership auditing beyond what it itself
  sets (`cron.allow`/`cron.deny` mode `0600`) — it does not check
  `/etc/cron.d`, `/etc/crontab`, or `/etc/cron.{hourly,daily,weekly,monthly}`
  for group/world-writable paths. If that kind of check is wanted, it has
  to be added to the role.
- `cron_setup_entries` only ever adds/removes the exact entries listed —
  it never reports or touches cron jobs that exist outside this variable,
  so ad hoc jobs a human created directly are left alone.
