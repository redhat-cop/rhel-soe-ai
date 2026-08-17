---
name: system_keyboard
description: Maintains the ansible/roles/system_keyboard Ansible role that audits and remediates the console (and optionally X11) keyboard layout on RHEL-family systems as part of the Linux SOE. Use when checking or setting the VC/X11 keymap via localectl.
---

# system_keyboard

Maintains `ansible/roles/system_keyboard/`. See `docs/ARCHITECTURE.md` for
the shared conventions.

## Baseline

Encoded in `ansible/roles/system_keyboard/defaults/main.yml`:

- Console keymap (`soe_keyboard_vc_keymap`, default `us`) matches
  `localectl status`'s `VC Keymap` line.
- X11 layout (`soe_keyboard_x11_layout`) is only checked/managed if
  `soe_keyboard_manage_x11` is explicitly set true (default false — most
  SOE targets are headless servers with no X11 session).

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags system_keyboard --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval. Applies via `localectl set-keymap` / `set-x11-keymap`, which
keeps the console/X11 config and (for the VC keymap) initramfs consistent
— this role does not hand-edit `/etc/vconsole.conf` directly.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/system_keyboard/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/system_keyboard/`,
`--check --diff`), push, and open a PR titled
`[system_keyboard] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `localectl` has no machine-readable `show`/`--property` output (unlike
  `timedatectl`/`systemctl`) — this role parses `localectl status` text
  instead. If a future systemd version changes that output format, this is
  the task to fix (`Get current keyboard status` in `tasks/main.yml`).
