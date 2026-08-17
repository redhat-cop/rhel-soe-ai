---
name: system_locale
description: Maintains the ansible/roles/system_locale Ansible role that audits and remediates the system locale (LANG and related settings) on RHEL-family systems as part of the Linux SOE. Use when checking or setting locale via localectl, or resolving locale warnings.
---

# system_locale

Maintains `ansible/roles/system_locale/`. See `docs/ARCHITECTURE.md` for
the shared conventions.

## Baseline

Encoded in `ansible/roles/system_locale/defaults/main.yml`:

- Target locale (`soe_locale_lang`, default `C.UTF-8`) is installed
  (checked against `localectl list-locales`) before anything tries to set
  it — setting `LANG` to an uninstalled locale causes
  `perl: warning: Setting locale failed`-style errors system-wide.
- `/etc/locale.conf`'s `LANG` matches the target.
- No conflicting `LANG`/`LC_*` overrides in `/etc/environment` or
  `/etc/profile.d/*.sh` (reported for manual review, not auto-removed).

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags system_locale --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval. Applies via `localectl set-locale`.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/system_locale/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/system_locale/`,
`--check --diff`), push, and open a PR titled
`[system_locale] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- Like `system_keyboard`, `localectl` has no `show`/`--property` output —
  the current-locale read here parses `/etc/locale.conf` directly instead
  of trying to scrape `localectl status` text.
- If the target locale isn't installed, the fix is
  `dnf reinstall glibc-langpack-<lang>` (or `dnf install`) — this role
  asserts the gap but doesn't install language packs itself, since the
  right package name varies by locale.
- `C.UTF-8` is the default baseline rather than a language-specific locale
  like `en_US.UTF-8`: it's provided by glibc itself (no `glibc-langpack-*`
  install required) and gives UTF-8 encoding without asserting an English
  (or any other) language preference, so it's still available on minimal
  installs and doesn't need a per-fleet/per-locale override just to pass
  the "is it installed" check.
