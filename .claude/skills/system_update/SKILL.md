---
name: system_update
description: Maintains the ansible/roles/system_update Ansible role that applies all available dnf updates and reboots per policy, optionally emailing/PDF-reporting the update list, as part of the Linux SOE. Use when checking for or applying pending package updates. See system_update_report_pre for a pre-update, non-applying version of the report.
---

# system_update

Maintains `ansible/roles/system_update/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_update/defaults/main.yml`:

- Always runs `dnf update *` (state: latest) — there's no enable/disable
  flag; gating this role's inclusion in a remediate run is the caller's job.
- `system_update_reboot_policy` (default `when_needed`, checked via
  `dnf needs-restarting`) — `never` / `when_needed` / `when_updated`
  (reboot only if the update task itself reported changed) / `always`.
- `system_update_display_updates` (default `false`) prints the updated-package
  list; `system_update_email_report` (default `false`) sends it via
  `community.general.mail` using `system_update_email_parameters`.
- `system_update_report_pdf` (default `false`) additionally generates a PDF on
  the **control host** using `enscript`/`ghostscript` — these must be
  installed separately on the control node, not the target.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_update`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_update --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_update
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_update/<short-desc>`, edit `ansible/roles/system_update/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_update/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_update] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Under `--check`, `dnf update *` doesn't perform the update, so
  `needs-restarting`-based reboot policy evaluation during an audit run
  reflects pre-update state, not what would be true post-update — treat
  `--check --diff` here as "what would be updated," not a reliable preview of
  whether a reboot would follow.
  A real (non-check) run of this role can update dozens of packages and
  reboot the host — always get explicit confirmation, same as any other
  fleet-wide package/reboot action.

## Wiring into the SOE

This role is deliberately **excluded** from `ansible/site.yml`'s default
`roles:` list (see the comment above that list, and the "excluded from the
default run" table in `.claude/skills/soe/SKILL.md`) because it acts
unconditionally with no guard variable and/or reboots, auto-updates, or
de-registers the host outright. It only runs when explicitly invoked with
`--tags system_update`, as shown above — never as a side effect of a full SOE
run. Don't add it back to `ansible/site.yml`'s default list without an
explicit decision from a human operator; that would be a cross-cutting,
high-blast-radius change in its own right.
