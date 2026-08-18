---
name: usbguard_setup
description: Maintains the ansible/roles/usbguard_setup Ansible role that installs USBGuard and enables/starts its service by default with a reject-all policy on RHEL-family systems as part of the Linux SOE. Use when checking or configuring USB device allow/block policy via usbguard. There is NO opt-in gate on service enablement — enforcement is on by default with policy=reject.
---

# usbguard_setup

Maintains `ansible/roles/usbguard_setup/`. See `docs/ARCHITECTURE.md` for
the shared conventions — this is the role with the highest blast radius in
the SOE. **Read this whole file before running remediate on any host with
only physical console access.**

## What the role actually does — service enablement is NOT opt-in

Encoded in `ansible/roles/usbguard_setup/defaults/main.yml`:

- `usbguard_setup_policy` (default `reject`): `reject` (default-deny, all
  connected devices blocked), `custom` (use
  `usbguard_setup_config_file`/`_rules_file`/`_ipc_access_file`), or
  `allow` (**disable** USBGuard and allow all USB devices).
- **There is no `soe_usbguard_manage_service`-style opt-in variable in
  this role.** Whenever `usbguard_setup_policy != 'allow'` (i.e. the
  default `reject`, or `custom`), the role installs USBGuard, writes the
  policy config, **enables and starts `usbguard.service`
  unconditionally**. With the default `policy: reject` and default
  `rules.conf` handling below, running this role's remediate path on an
  unconfigured host applies a default-block USB policy and turns on
  enforcement in the same run.
- If `usbguard_setup_rules_file` is unset (the default), the role writes
  an **empty** `/etc/usbguard/rules.conf` — it does **not** run
  `usbguard generate-policy` to seed an allow-list from currently-attached
  devices. Combined with default `policy: reject` and unconditional
  service enablement, the out-of-the-box remediate behavior is: empty
  allow-list + reject-all + service started — which can block *all* USB
  devices including a keyboard/mouse on a host with only physical console
  access.
- `usbguard_setup_exclusive: true` removes unrecognized rules/IPC files
  not in `usbguard_setup_files_known` via `include_role: files_remove` —
  **that role is not vendored in this repository**; it must be resolvable
  separately for `_exclusive: true` to work.
- `policy: allow` takes the opposite path entirely (`disable.yml`):
  disables and stops `usbguard.service` if the package is present, does
  not touch config files.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- usbguard_setup`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags usbguard_setup` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags usbguard_setup --check --diff`

**Before any remediate run on a host that is not `policy: allow`**:
confirm with the user (a) they have a non-USB or already-reviewed access
path (remote console, iDRAC/iLO, an already-allow-listed keyboard/mouse),
and (b) whether `usbguard_setup_rules_file` should point at a real,
reviewed rules template — since the default is an empty rules file and
this role enables enforcement in the same run, not a separate step:

```
ansible-playbook ansible/configure_rhel.yml --tags usbguard_setup
```

**To explicitly disable enforcement instead** (allow all USB devices,
service off): set `usbguard_setup_policy: allow`.

**Propose a change to the role itself** — especially anything touching
default service enablement or the empty-rules-file default: never commit
directly, and flag it explicitly in the PR body given this role's blast
radius. On a branch named `soe/usbguard_setup/<short-desc>`, edit the
role, validate locally (`--syntax-check`,
`ansible-lint roles/usbguard_setup/`, `--check --diff`), push, and open a
PR titled `[usbguard_setup] <what changed>` — then stop for human review.
See `docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes — read before touching this role

- **Do not describe this role's service enablement as opt-in or
  safety-gated — it is not, as currently implemented.** If the user
  expects an opt-in gate (e.g. from prior documentation or another SOE
  role's pattern), flag that mismatch explicitly rather than assuming the
  gate exists.
- Always get explicit confirmation of another access path before a
  remediate run with `policy: reject`/`custom` on a host with only
  physical console access — the empty default `rules.conf` plus
  unconditional service start is the exact combination that can lock out
  a physically-connected keyboard/mouse.
- `usbguard_setup_exclusive: true` depends on an external `files_remove`
  role this repo does not vendor — confirm it's resolvable before relying
  on it.
