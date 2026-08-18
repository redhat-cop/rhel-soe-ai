---
name: system_update
description: Maintains the ansible/roles/system_update Ansible role that applies all available dnf updates and reboots per policy, optionally emailing/PDF-reporting the update list, as part of the Linux SOE. Use when checking for or applying pending package updates. See system_update_report_pre for a pre-update, non-applying version of the report.
---

# system_update

Maintains `ansible/roles/system_update/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

`ansible/roles/system_update/README.md` documents this role's full
configuration surface (every `defaults/main.yml` variable, with its
original inline comments, rendered as a single reference). Read it
before proposing or explaining how to configure this role — it
reflects the role's actual current defaults even if a variable summary
elsewhere in this file has drifted out of sync with the role.

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
ansible-playbook ansible/update_rhel.yml --tags system_update --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/update_rhel.yml --tags system_update
```

Note this only works if `system_update` has been uncommented in
`ansible/update_rhel.yml`'s `roles:` list first (it sits directly below
`system_update_report_pre` there, commented out by default) — see "Wiring
into the SOE" below; by default the tag matches nothing.

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

This role is **commented out** in both playbooks that mention it:
`ansible/update_rhel.yml` (`#- system_update`, right after the active
`system_update_report_pre` — see that role's `SKILL.md`) and
`ansible/configure_rhel.yml` (`#- system_update`, also commented). It is
not in any of the other playbooks
(`load_balancer_setup.yml`/`nfs_client_setup.yml`/`nfs_server_setup.yml`/
`connect_linux.yml`) at all. This is deliberate: it acts unconditionally
with no guard variable (`dnf update *`, always) and can reboot the host, so
it must never run as a side effect of a routine run of either playbook.

Uncomment it in `ansible/update_rhel.yml` (the natural home, alongside its
pre-update report counterpart) when fleet-wide patching is actually wanted,
run the commands above, then comment it back out — or propose making that
change more permanent via the branch + PR workflow if the intent is to
patch regularly rather than as a one-off. This repo no longer uses
`ansible/site.yml`; see `docs/ARCHITECTURE.md`.
