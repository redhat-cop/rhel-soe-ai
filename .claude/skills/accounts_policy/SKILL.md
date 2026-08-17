---
name: accounts_policy
description: Maintains the ansible/roles/accounts_policy Ansible role that audits and remediates local account and password policy (aging, complexity, UID ranges, empty passwords, sudoers hygiene) on RHEL-family systems as part of the Linux SOE. Use when checking or hardening local user account policy.
---

# accounts_policy

Maintains `ansible/roles/accounts_policy/`. See `docs/ARCHITECTURE.md` for
the shared conventions (role layout, audit vs. remediate, safety rules) and
`timesync`'s `SKILL.md` for the fullest-documented example of this pattern.

## Baseline

Encoded in `ansible/roles/accounts_policy/defaults/main.yml`:

- Password aging in `/etc/login.defs`: `PASS_MAX_DAYS`, `PASS_MIN_DAYS`,
  `PASS_WARN_AGE` (defaults 90/1/7).
- Password quality via `/etc/security/pwquality.conf`
  (`soe_accounts_pwquality`: `minlen`, `dcredit`, `ucredit`, `lcredit`,
  `ocredit`).
- No accounts with empty passwords (detected via `/etc/shadow`).
- No duplicate UIDs.
- `/etc/sudoers` and `/etc/sudoers.d/*` are mode `0440`
  (`soe_accounts_sudoers_paths`).

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags accounts_policy --check --diff`

**Remediate**: same command without `--check`, only after explicit user
approval — this role edits `login.defs`, `pwquality.conf`, and sudoers file
permissions on the target host.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/accounts_policy/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/accounts_policy/`,
`--check --diff`), push, and open a PR titled
`[accounts_policy] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes — things this role deliberately does NOT auto-fix

- **Password aging (`PASS_MAX_DAYS`/`PASS_MIN_DAYS`/`PASS_WARN_AGE`)** is
  enforced via `/etc/login.defs`, which `useradd` only reads at
  account-creation time — this baseline applies to *newly created* accounts
  going forward, not retroactively to existing ones. Existing accounts'
  aging lives in `/etc/shadow` per-user and needs `chage`, which (like
  locking an account) is a per-account judgment call this role doesn't
  make automatically.
- **Empty-password accounts** and **duplicate UIDs** are reported via
  `assert` (task fails, `fail_msg` lists the accounts/UIDs) but never
  auto-locked or auto-renumbered — locking (`usermod -L`) or fixing a UID
  is a judgment call on a specific account, not a safe blanket action.
- **`NOPASSWD:ALL` sudoers entries** are reported for review
  (`ansible.builtin.debug`) but never removed automatically.
- Sudoers edits made manually (not by this role) should always go through
  `visudo -c` — a syntax error in sudoers can lock out `sudo` entirely.
