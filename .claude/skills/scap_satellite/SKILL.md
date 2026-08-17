---
name: scap_satellite
description: Maintains the ansible/roles/scap_satellite Ansible role that runs foreman_scap_client against Satellite/Capsule-defined compliance policies, as part of the Linux SOE. Use when checking OpenSCAP compliance reported through Satellite rather than run locally (see scap_compliance for a standalone oscap run).
---

# scap_satellite

Maintains `ansible/roles/scap_satellite/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/scap_satellite/defaults/main.yml`:

- Requires the host already registered to Satellite/Capsule, and
  Satellite/Capsule itself already configured with the referenced policies —
  this role only runs the client-side scan.
- `scap_satellite_server`/`_port`/`_timeout` point at the Capsule; unlike
  `scap_compliance`, the actual profile selection lives in Satellite's own
  Compliance Policies, referenced here by `scap_satellite_policies` (list of
  `id`/`profile`, optionally `tailoring_id`/`tailoring_profile`).
- `scap_satellite_refresh_policy_files` (default `false`) — reuses cached
  policy files unless forced.
- `scap_satellite_fetch_remote_resources` (default `false`) — passed to oscap;
  enabling lets the scan pull remote SCAP content, an outbound-network and
  supply-chain consideration.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/scap_satellite`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags scap_satellite --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags scap_satellite
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/scap_satellite/<short-desc>`, edit `ansible/roles/scap_satellite/`, validate
locally (`--syntax-check`, `ansible-lint roles/scap_satellite/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[scap_satellite] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This role reports compliance status to Satellite; it does not remediate —
  don't conflate a clean run here with `scap_compliance`'s remediation
  capability when summarizing results to the user.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags scap_satellite ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
