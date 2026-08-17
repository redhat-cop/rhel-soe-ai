---
name: usbguard_setup
description: Maintains the ansible/roles/usbguard_setup Ansible role that audits and remediates USBGuard device authorization policy on RHEL-family systems as part of the Linux SOE. Use when checking or configuring USB device allow/block policy via usbguard. Service enablement is opt-in due to physical lockout risk.
---

# usbguard_setup

Maintains `ansible/roles/usbguard_setup/`. See `docs/ARCHITECTURE.md` for
the shared conventions — this is the role with the highest blast radius in
the SOE, and its safety design is documented there too.

## Baseline

Encoded in `ansible/roles/usbguard_setup/defaults/main.yml`:

- `usbguard` package installed.
- `/etc/usbguard/usbguard-daemon.conf`: `ImplicitPolicyTarget=block`
  (default-deny — confirm this matches org policy before relying on it).
- `/etc/usbguard/rules.conf` exists (mode `0600`); if it doesn't, the role
  generates one from currently-connected devices via
  `usbguard generate-policy` so there's an initial allow-list rather than
  an empty default-block policy.
- `usbguard.service` enabled/started **only if**
  `soe_usbguard_manage_service: true` is explicitly set (default `false`).

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags usbguard_setup --check --diff`

**Remediate** (installs usbguard, writes/permission-fixes `rules.conf`,
but does **not** enable the service by default):

```
ansible-playbook ansible/site.yml --tags usbguard_setup
```

**To actually enable enforcement**: only after the user has reviewed
`/etc/usbguard/rules.conf` on the target host and confirmed it allows the
devices that need to keep working (especially keyboard/mouse on a host
with only physical console access), run with the opt-in flag set:

```
ansible-playbook ansible/site.yml --tags usbguard_setup -e soe_usbguard_manage_service=true
```

**Propose a change to the role itself** (e.g. changing the default
`ImplicitPolicyTarget` policy): never commit directly, and be extra
conservative here given this role's blast radius — flag anything touching
the default enablement behavior explicitly in the PR body. On a branch
named `soe/usbguard_setup/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/usbguard_setup/`, `--check --diff`),
push, and open a PR titled `[usbguard_setup] <what changed>` — then stop
for human review. See `docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes — read before touching this role

- Enabling a default-block USBGuard policy on a system with **only
  physical console access** and no reviewed HID allow rule can lock out
  the keyboard/mouse. This is why `soe_usbguard_manage_service` defaults to
  `false` — get explicit confirmation from the user that they've reviewed
  the policy and have another access path (remote console, iDRAC/iLO, SSH)
  before setting it to `true`.
