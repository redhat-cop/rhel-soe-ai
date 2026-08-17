---
name: system_reboot
description: Maintains the ansible/roles/system_reboot Ansible role that reboots a host per a configurable policy, as part of the Linux SOE. Use when asked to reboot a host as a standalone, policy-driven action (distinct from the reboot-on-change behavior baked into several other roles).
---

# system_reboot

Maintains `ansible/roles/system_reboot/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_reboot/defaults/main.yml`:

- `system_reboot_policy` (default `when_needed`) — `never` / `when_needed`
  (checks `dnf needs-restarting`) / `always`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_reboot`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_reboot --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_reboot
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_reboot/<short-desc>`, edit `ansible/roles/system_reboot/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_reboot/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_reboot] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This role's sole purpose is to reboot the host — treat any remediate run
  including it the same as the reboot warnings called out for
  `boot_parameters`/`system_locale` in `soe/SKILL.md`: confirm explicitly
  before running without `--check` if `system_reboot_policy` isn't `never`.

## Wiring into the SOE

This role is deliberately **excluded** from `ansible/site.yml`'s default
`roles:` list (see the comment above that list, and the "excluded from the
default run" table in `.claude/skills/soe/SKILL.md`) because it acts
unconditionally with no guard variable and/or reboots, auto-updates, or
de-registers the host outright. It only runs when explicitly invoked with
`--tags system_reboot`, as shown above — never as a side effect of a full SOE
run. Don't add it back to `ansible/site.yml`'s default list without an
explicit decision from a human operator; that would be a cross-cutting,
high-blast-radius change in its own right.
