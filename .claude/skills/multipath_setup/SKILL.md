---
name: multipath_setup
description: Maintains the ansible/roles/multipath_setup Ansible role that installs device-mapper-multipath and deploys /etc/multipath.conf and bindings, restarting or rebooting on change, as part of the Linux SOE. Use when checking or fixing multipath configuration.
---

# multipath_setup

Maintains `ansible/roles/multipath_setup/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/multipath_setup/defaults/main.yml`:

- `multipath_setup_config_file`/`multipath_setup_bindings_file` default unset
  — config/bindings copy, and the resulting `multipathd` enable, only happen
  when a source file is actually provided.
- `multipath_setup_reboot` (default **`true`**) — on change, the role reboots
  by default rather than reloading `multipathd`; set `false` to instead
  `start`/`reload` the service in place after a `dracut -f --regenerate-all`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/multipath_setup`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags multipath_setup --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags multipath_setup
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/multipath_setup/<short-desc>`, edit `ansible/roles/multipath_setup/`, validate
locally (`--syntax-check`, `ansible-lint roles/multipath_setup/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[multipath_setup] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Default behavior on this role is to reboot after any config/bindings
  change — on a host with active multipath I/O this is disruptive; confirm
  before a real remediate run, or pass
  `-e multipath_setup_reboot=false` if a live reload is acceptable instead.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags multipath_setup ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
