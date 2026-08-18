---
name: accounts_local
description: Maintains the ansible/roles/accounts_local Ansible role that creates/deletes local users and groups, sets passwords, sudoers entries, supplementary groups, and SSH authorized keys, as part of the Linux SOE. Use when checking or fixing local (non-domain) account/group state.
---

# accounts_local

Maintains `ansible/roles/accounts_local/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/accounts_local/defaults/main.yml`:

- All four lists (`accounts_local_users_delete`, `accounts_local_groups_delete`,
  `accounts_local_groups_create`, `accounts_local_users_create`) default empty —
  the role does nothing until a host/group sets one.
- User/group name validation is enforced via `ansible.builtin.assert` (length,
  no `.`/`..`, no leading `-`, not purely numeric, not `root`/`sshd`, must match
  `^[A-Za-z0-9_.]+(?:\$)?$`) before create.
- `root` and `sshd` are hard-excluded from deletion regardless of what's listed.
- Passwords: `accounts_local_password_encrypted` controls whether
  `accounts_local_users_create[].password` is treated as already-hashed or
  hashed in-role with a per-host salt derived from `accounts_local_password_salt_seed`
  (default `{{ inventory_hostname }}`); `accounts_local_no_log: true` by default
  suppresses password values from logs/output.
- Per-user `sudo_allow_all: true` creates `/etc/sudoers.d/<user>` (validated with
  `visudo -csf`); `sudo_passwordless: true` makes that entry `NOPASSWD`. Neither
  is set by default.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/accounts_local`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is off by default** in `ansible/configure_rhel.yml` — every
> role there (active or not) is gated by a single `configure_rhel_domains`
> list variable (`when: "'<name>' in configure_rhel_domains"`), and `accounts_local`
> isn't in the default value of that list. Nothing needs editing in the
> playbook itself to turn it on: pass the *full* desired domain list via
> `-e`, e.g.
> `-e '{"configure_rhel_domains": [...the default 20..., "accounts_local"]}'`
> (see `.claude/skills/configure_rhel/SKILL.md` for the current default list
> to extend, and why it has to be the full list, not just the addition —
> `-e` replaces the variable's value, it doesn't merge into it). `--tags accounts_local`
> alone is **not** enough — the domains list and `--tags`/`--skip-tags` are
> separate, ANDed gates, both verified independently: a role only runs if
> it's in `configure_rhel_domains` *and* matches the requested tags. Some
> roles (this one — check its `defaults/main.yml` and task file) also have
> their own internal enable flag or required variable on top of that, which
> still needs setting the same as before. Flag all of this to the user before
> assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags accounts_local --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags accounts_local
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/accounts_local/<short-desc>`, edit `ansible/roles/accounts_local/`, validate
locally (`--syntax-check`, `ansible-lint roles/accounts_local/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[accounts_local] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Deleting a user with `remove: true, force: true` removes their home directory —
  confirm with the user before proposing/running a delete.
- `sudo_passwordless: true` grants unattended root — flag this explicitly rather
  than silently accepting it in a proposed change.

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table. It's
present (not commented out) in `ansible/configure_rhel.yml`'s `roles:` list,
gated by `configure_rhel_domains` — off by default, on via `-e` — see the
caveat at the top of "What to do" above and
`.claude/skills/configure_rhel/SKILL.md`. It is not referenced by any of the
other playbooks (`load_balancer_setup.yml`, `nfs_client_setup.yml`,
`nfs_server_setup.yml`, `update_rhel.yml`, `connect_linux.yml`) either. This
repo no longer uses `ansible/site.yml`; see `docs/ARCHITECTURE.md`.
