---
name: audit_setup
description: Maintains the ansible/roles/audit_setup Ansible role that installs auditd, deploys an auditd.conf and rules file from role-provided templates, and manages the locked-rules reload/reboot behavior on RHEL-family systems as part of the Linux SOE. Use when checking or configuring auditd/audit rules.
---

# audit_setup

Maintains `ansible/roles/audit_setup/`. See `docs/ARCHITECTURE.md` for the
shared conventions.

## What the role actually does

Encoded in `ansible/roles/audit_setup/defaults/main.yml`:

- Fails immediately if `audit=0`/`audit=off` is on the running kernel
  command line (checked via `ansible_facts.cmdline`).
- Installs the `audit` package.
- If `audit_setup_config_file` is set, copies it to `/etc/audit/auditd.conf`
  (role-provided alternatives: `auditd_rhel.conf`, `auditd_cis.conf`,
  `auditd_cis.conf_rhel8`) — otherwise the file is left as-is.
- If `audit_setup_rules_file` is set, copies it to
  `/etc/audit/rules.d/zz-ansible.rules` — otherwise no rules file is
  deployed. Both variables are unset by default; nothing is enforced
  content-wise out of the box.
- If `audit_setup_exclusive: true`, removes any `/etc/audit/rules.d/*` file
  not in `audit_setup_files_known` (default: `[/etc/audit/rules.d/audit.rules]`)
  or the role's own `zz-ansible.rules`, via an `include_role: files_remove`
  call. **That `files_remove` role is not part of this repository** — it
  must be resolved from elsewhere (Galaxy/local roles path) for
  `audit_setup_exclusive: true` to work at all.
- Enables/starts `auditd.service`.
- If rules changed and the currently-loaded rules aren't locked
  (`auditctl -s` doesn't report `enabled 2`), reloads via `service auditd
  reload` (the `ansible.builtin.service` module isn't compatible with
  auditd — see the code comment citing
  https://access.redhat.com/solutions/2664811).
- If rules changed **and** they're locked **and**
  `audit_setup_update_lock == 'reboot'`, **reboots the host**
  (`ansible.builtin.reboot`) to apply them. If locked and
  `audit_setup_update_lock == 'fail'` (the default), the role fails the
  play instead. `'ignore'` silently leaves the old rules active.

## What to do

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags audit_setup --check --diff`.
The `augenrules --check` and `auditctl -s` reads are `command` tasks marked
`check_mode: false`, so they run and report real state under `--check`.

**Remediate**: same command without `--check`, after explicit user
approval. **If `audit_setup_update_lock` is left at its default `fail`**
and the current rules are locked, remediation will fail the play rather
than silently doing nothing — that's expected, not a bug. **If it's set to
`reboot`**, remediating with locked+changed rules reboots the host; get
explicit confirmation before running with that setting.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/audit_setup/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/audit_setup/`,
`--check --diff`), push, and open a PR titled
`[audit_setup] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Neither `audit_setup_config_file` nor `audit_setup_rules_file` has a
  default — this role ships no auditd config or rule content by default,
  by design (rule sets are org/compliance-framework specific). Pick one of
  the role-provided templates or supply your own before relying on this
  role for anything.
- `audit_setup_exclusive: true` depends on an external `files_remove` role
  this repo does not vendor — confirm it's resolvable before enabling.
