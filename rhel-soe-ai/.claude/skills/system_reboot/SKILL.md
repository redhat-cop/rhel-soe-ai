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
ansible-playbook ansible/configure_rhel.yml --tags system_reboot --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags system_reboot
```

Note this only works at all if `system_reboot` has been uncommented in
`ansible/configure_rhel.yml`'s `roles:` list first — see "Wiring into the
SOE" below; by default the tag matches nothing.

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

This role is **not present at all** in `ansible/configure_rhel.yml`'s
`roles:` list — not even as a commented-out line, unlike most of the
"opt-in" roles in this repo (see `.claude/skills/soe/SKILL.md`'s "excluded
from the default run" table) — nor in any of the other playbooks
(`load_balancer_setup.yml`, `nfs_client_setup.yml`, `nfs_server_setup.yml`,
`update_rhel.yml`, `connect_linux.yml`). This is deliberate: it acts
unconditionally with no guard variable, and its entire purpose is to reboot
the host, so it must never run as a side effect of a routine baseline run.

To actually invoke it, add `- system_reboot` (and any `system_reboot_policy`
override) directly to `ansible/configure_rhel.yml`'s `roles:` list yourself
before running the commands above, or write a small dedicated one-off
playbook — either way, propose it via the branch + PR workflow, and treat
adding it to `configure_rhel.yml` permanently as a cross-cutting,
high-blast-radius change needing an explicit human decision, same as it was
under the old `ansible/site.yml`. This repo no longer uses
`ansible/site.yml`; see `docs/ARCHITECTURE.md`.
