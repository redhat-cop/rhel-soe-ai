---
name: system_update_report_pre
description: Maintains the ansible/roles/system_update_report_pre Ansible role that reports (without applying) pending dnf updates, optionally emailing/PDF-reporting the list, as part of the Linux SOE. Use when asked what updates are pending without installing them — see system_update for the role that actually applies updates.
---

# system_update_report_pre

Maintains `ansible/roles/system_update_report_pre/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_update_report_pre/defaults/main.yml`:

- Read-only by construction — it lists what `dnf update` *would* install,
  it never runs the update itself, so this role behaves the same under
  `--check` and without it.
- `system_update_report_pre_display_updates`/`_email_report`/`_pdf` mirror
  `system_update`'s equivalent flags (all default `false`) but describe
  pending, not applied, updates — same PDF caveat: generated on the control
  host, needs `enscript`/`ghostscript` there.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_update_report_pre`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_update_report_pre --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_update_report_pre
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_update_report_pre/<short-desc>`, edit `ansible/roles/system_update_report_pre/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_update_report_pre/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_update_report_pre] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags system_update_report_pre ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
