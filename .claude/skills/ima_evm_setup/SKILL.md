---
name: ima_evm_setup
description: Maintains the ansible/roles/ima_evm_setup Ansible role that enables or disables IMA/EVM file-integrity appraisal via a signed policy file, as part of the Linux SOE. Use when checking or fixing IMA/EVM state. Only applies on RHEL 9.7+; no-ops (with a gathered-fact check) on older releases.
---

# ima_evm_setup

Maintains `ansible/roles/ima_evm_setup/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/ima_evm_setup/defaults/main.yml`:

- `ima_evm_setup_enable: null` (default) leaves current IMA/EVM state
  untouched — same null-means-noop pattern as `firewall_enable`.
- Only takes effect when `ansible_facts.distribution_version | float >= 9.7`
  (gathered if not already present); silently does nothing on 9.6 and earlier.
- `ima_evm_setup_policy_config_file` (default:
  `/usr/share/ima/policies/01-appraise-executable-and-lib-signatures`, part of
  `ima-evm-utils`) must already exist **on the target** — this is not a local
  file copied by the role.
- `ima_evm_setup_verify_policy` (default `true`) validates the new policy
  before applying; because the mechanism *appends* to the current policy
  rather than replacing it, the combined policy is only actually in effect
  after a reboot.
- `ima_evm_setup_reboot` (default `false`) — disabling IMA fully requires a
  reboot to complete per the role's own note.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/ima_evm_setup`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags ima_evm_setup --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags ima_evm_setup
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/ima_evm_setup/<short-desc>`, edit `ansible/roles/ima_evm_setup/`, validate
locally (`--syntax-check`, `ansible-lint roles/ima_evm_setup/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[ima_evm_setup] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- A bad or overly strict appraisal policy can block executables/libraries
  from running after reboot — this is a boot-risk change in the same class as
  `boot_parameters`; treat proposed policy-file changes with the same caution
  and confirm before a real remediate run that reboots.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags ima_evm_setup ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
