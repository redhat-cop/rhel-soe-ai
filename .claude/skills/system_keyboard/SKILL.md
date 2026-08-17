---
name: system_keyboard
description: Maintains the ansible/roles/system_keyboard Ansible role that sets the console keymap and console font (via /etc/vconsole.conf, localectl, setfont, and an initramfs rebuild) on RHEL-family systems as part of the Linux SOE. Use when checking or setting the virtual console keymap/font. Does not manage X11 keyboard layout — there is no X11 handling in this role.
---

# system_keyboard

Maintains `ansible/roles/system_keyboard/`. See `docs/ARCHITECTURE.md` for
the shared conventions.

## What the role actually does

Encoded in `ansible/roles/system_keyboard/defaults/main.yml`:

- `system_keyboard` (default `us`): checked against `/etc/vconsole.conf`'s
  `KEYMAP=` line via a `check_mode: true` `lineinfile` probe; if not
  already set, applies via `localectl set-keymap`.
- `system_font` (default `eurlatgr`): same pattern for `FONT=`, but
  applied by directly rewriting the line with `replace` (not
  `localectl`) and then running `setfont` to apply it live.
- Installs `kbd` and `kbd-misc` first.
- If the package install, keymap change, or font change did anything,
  rebuilds the initramfs with `dracut -f --regenerate-all`.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- system_keyboard`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags system_keyboard` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags system_keyboard --check --diff`.
The keymap/font check tasks use `lineinfile` in `check_mode: true`
internally (a self-contained probe), so they report accurately regardless
of the outer `--check` flag — but the `localectl`, `setfont`, and `dracut`
tasks are normal `command` tasks and are skipped entirely under the outer
`--check`, so an audit run won't show their effect, only whether they'd
run.

**Remediate**: same command without `--check`, after explicit user
approval. A `dracut -f --regenerate-all` full initramfs rebuild is
comparatively slow and runs whenever the package install, keymap, or font
task reports changed — factor that into how disruptive a remediate run is
expected to be.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/system_keyboard/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/system_keyboard/`,
`--check --diff`), push, and open a PR titled
`[system_keyboard] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- There is no X11 keyboard layout management in this role at all — it is
  virtual-console only. Most SOE targets are headless servers, which is
  presumably why, but don't describe this role as covering X11 layout.
- `system_font` is applied via a hand-written `replace` on
  `/etc/vconsole.conf`, not `localectl set-font`/an equivalent — if a
  future systemd/`localectl` adds first-class font management, this task
  is the one to revisit.
