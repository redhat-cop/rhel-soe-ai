---
name: scap_compliance
description: Maintains the ansible/roles/scap_compliance Ansible role that runs oscap against a chosen OpenSCAP profile (default cis) and can auto-remediate findings, as part of the Linux SOE. Use when checking or fixing OpenSCAP/SCAP compliance.
---

# scap_compliance

Maintains `ansible/roles/scap_compliance/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/scap_compliance/defaults/main.yml`:

- `scap_compliance_profile` (default `cis`) selects the
  `xccdf_org.ssgproject.content_profile_<profile>` profile from the RPM-provided
  scap-security-guide datastream (or `scap_compliance_content_file_path` if
  overridden); the role's own comment warns switching profiles later is
  unsupported.
- `scap_compliance_remediate` (default **`false`**) — with it `false` the role
  runs `oscap xccdf eval` as an audit-only report; only with it `true` does the
  underlying command run `--remediate` and actually change the system. This is
  the one role in the repo where audit vs. remediate is a role *variable*, not
  the `--check`/no-`--check` Ansible flag — passing `--check --diff` alone does
  **not** make this role read-only if `scap_compliance_remediate: true`.
- `scap_compliance_remediate_reboot` (default **`true`**) — reboots after a
  remediation that changed something.
- `scap_compliance_check_fail_role_pass` (default `false`) — by default a
  failed compliance check fails the Ansible run; set `true` to let the role
  complete regardless and rely on the report file instead.
- Results land in `scap_compliance_report_dir` (default `/root/oscap/results`)
  — only the most recent run's results are kept.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/scap_compliance`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- scap_compliance`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags scap_compliance` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags scap_compliance --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags scap_compliance
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/scap_compliance/<short-desc>`, edit `ansible/roles/scap_compliance/`, validate
locally (`--syntax-check`, `ansible-lint roles/scap_compliance/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[scap_compliance] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Because `scap_compliance_remediate` (not `--check`) gates whether the
  system is actually changed, treat any request to "check compliance" as
  requiring `scap_compliance_remediate: false` explicitly (the default) unless
  the user has asked to remediate — running `--check --diff` against this role
  with `scap_compliance_remediate: true` set will still remediate the host.
  The role's own comment also states reverting SCAP remediation is not
  supported — there's no automatic undo.

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but is
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list by default
(`#- scap_compliance`) — see the caveat at the top of "What to do" above. It is not
referenced by any of the other playbooks (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, `update_rhel.yml`,
`connect_linux.yml`) either. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
