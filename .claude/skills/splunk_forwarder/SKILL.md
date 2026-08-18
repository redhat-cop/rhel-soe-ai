---
name: splunk_forwarder
description: Maintains the ansible/roles/splunk_forwarder Ansible role that configures the Splunk universal forwarder's deployment-server pointer and local splunk user, as part of the Linux SOE. Use when checking or fixing Splunk forwarder deployment-server configuration.
---

# splunk_forwarder

Maintains `ansible/roles/splunk_forwarder/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/splunk_forwarder/defaults/main.yml`:

- `splunk_deployment_server` is unset by default — the deployment-server and
  user config templates only take effect once it's set.
  `splunk_deployment_server_check` (default `true`) verifies reachability.
- `splunk_user_uid` (default `4445`) — a local `splunk` user is created at this
  UID if no local/remote user already exists; set to undefined/none instead to
  get a system account.
- `splunk_user_password_hash` is expected from vault, unset by default.
- `splunk_phonehome_secs` (default `600`) is the forwarder's check-in
  interval.
- `splunk_deployment_config_file`/`splunk_user_config_file` let a host
  override the role-provided default templates.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/splunk_forwarder`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is off by default** in `ansible/configure_rhel.yml` — every
> role there (active or not) is gated by a single `configure_rhel_domains`
> list variable (`when: "'<name>' in configure_rhel_domains"`), and `splunk_forwarder`
> isn't in the default value of that list. Nothing needs editing in the
> playbook itself to turn it on: pass the *full* desired domain list via
> `-e`, e.g.
> `-e '{"configure_rhel_domains": [...the default 20..., "splunk_forwarder"]}'`
> (see `.claude/skills/configure_rhel/SKILL.md` for the current default list
> to extend, and why it has to be the full list, not just the addition —
> `-e` replaces the variable's value, it doesn't merge into it). `--tags splunk_forwarder`
> alone is **not** enough — the domains list and `--tags`/`--skip-tags` are
> separate, ANDed gates, both verified independently: a role only runs if
> it's in `configure_rhel_domains` *and* matches the requested tags. Some
> roles (this one — check its `defaults/main.yml` and task file) also have
> their own internal enable flag or required variable on top of that, which
> still needs setting the same as before. Flag all of this to the user before
> assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags splunk_forwarder --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags splunk_forwarder
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/splunk_forwarder/<short-desc>`, edit `ansible/roles/splunk_forwarder/`, validate
locally (`--syntax-check`, `ansible-lint roles/splunk_forwarder/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[splunk_forwarder] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table. It's
present (not commented out) in `ansible/configure_rhel.yml`'s `roles:` list,
gated by `configure_rhel_domains` — off by default, on via `-e` — see the
caveat at the top of "What to do" above and
`.claude/skills/configure_rhel/SKILL.md`. It is not referenced by any of the
other playbooks (`load_balancer_setup.yml`, `nfs_client_setup.yml`,
`nfs_server_setup.yml`, `update_rhel.yml`, `connect_linux.yml`) either. This
repo no longer uses `ansible/site.yml`; see `docs/ARCHITECTURE.md`.
