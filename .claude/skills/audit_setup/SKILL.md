---
name: audit_setup
description: Maintains the ansible/roles/audit_setup Ansible role that audits and remediates the Linux audit subsystem (auditd service, config, and rules) on RHEL-family systems as part of the Linux SOE. Use when checking or configuring auditd/auditctl.
---

# audit_setup

Maintains `ansible/roles/audit_setup/`. See `docs/ARCHITECTURE.md` for the
shared conventions (role layout, audit vs. remediate, safety rules).

## Baseline

Encoded in `ansible/roles/audit_setup/defaults/main.yml`:

- `audit` package installed; `auditd.service` enabled and active.
- `/etc/audit/auditd.conf`: `max_log_file_action=rotate`,
  `space_left_action` and `admin_space_left_action` set to something other
  than the default `ignore` (default here: `syslog`), `max_log_file` and
  `num_logs` reflecting retention policy.
- At least one `*.rules` file exists under `/etc/audit/rules.d/` — this
  role checks presence, not rule *content*, since the actual rule set is
  org-specific.

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags audit_setup --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval. Note the `auditd.conf` edits trigger a `Restart auditd` handler.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/audit_setup/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/audit_setup/`,
`--check --diff`), push, and open a PR titled
`[audit_setup] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- If the "audit rules present" assert fails, that's a signal to add the
  org's approved rule set under `/etc/audit/rules.d/*.rules` and run
  `augenrules --load` — this role deliberately doesn't ship or invent rule
  content, since audit rules are highly org/compliance-framework specific
  (PCI-DSS, STIG, CIS all differ).
- Setting audit rules immutable (`-e 2` as the last rule) requires a reboot
  to undo — this role does not manage that setting; treat it as a manual,
  reviewed step if the org requires it.
