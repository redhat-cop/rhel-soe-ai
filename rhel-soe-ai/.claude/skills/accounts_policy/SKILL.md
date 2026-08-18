---
name: accounts_policy
description: Maintains the ansible/roles/accounts_policy Ansible role that deploys local account, login, PAM, and password-quality configuration (login.defs, pwquality.conf, faillock.conf, limits.conf, authselect profile) on RHEL-family systems as part of the Linux SOE. Use when checking or changing local account/authentication policy.
---

# accounts_policy

Maintains `ansible/roles/accounts_policy/`. See `docs/ARCHITECTURE.md` for
the shared conventions (role layout, `--check --diff`, safety rules).

## What the role actually does

This role does **not** assert individual policy values (e.g. it never
checks "is `PASS_MAX_DAYS` 90?"). It deploys whole config files from
role-provided templates/files, each independently optional — any variable
left unset in `defaults/main.yml` means that file is left untouched:

- `useradd_defaults_file` → `/etc/default/useradd`
- `login_defs_config_file` → `/etc/login.defs`
- `login_access_config_file` → `/etc/security/access.conf`
- `faillock_config_file` → `/etc/security/faillock.conf`
- `pwhistory_config_file` → `/etc/security/pwhistory.conf`
- `pwquality_config_file` → `/etc/security/pwquality.conf`
- `limits_config_file` → `/etc/security/limits.conf`
- `user_resource_limits` (list) → `/etc/security/limits.d/95-ansible.conf`
- `system_auth_profile` (+ `system_auth_profile_parameters`) → installs
  `authselect`, optionally copies a `custom/*` profile to
  `/etc/authselect/custom`, and runs `authselect select -f <profile>
  <parameters>` if the currently-selected profile doesn't match
- `system_auth_pam_d_su_file` → `/etc/pam.d/su`

Each variable's docstring in `defaults/main.yml` lists the role-provided
template alternatives (e.g. `login_defs_config_file` can be
`login.defs_cis_rhel89.j2`, `login.defs_rhel_rhel8.j2`, etc. — pick per
RHEL major version and compliance target). Nothing is configured out of
the box: every one of these is unset by default.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- accounts_policy`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags accounts_policy` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags accounts_policy --check --diff`.
Note: the `authselect current`/`authselect check` steps are
`command` tasks — they run under `--check` (marked `check_mode: false`) so
drift there is still visible, but the `authselect select` task itself is a
normal `command` and is skipped under `--check`, so a check run won't show
its own diff.

**Remediate**: same command without `--check`, only after explicit user
approval and after confirming which template/profile variables are
actually set — an unset variable is a no-op, not a "use defaults" signal.

**Propose a change to the role itself**: never commit directly. On a
branch named `soe/accounts_policy/<short-desc>`, edit the role, validate
locally (`--syntax-check`, `ansible-lint roles/accounts_policy/`,
`--check --diff`), push, and open a PR titled
`[accounts_policy] <what changed>` with the `--check --diff` output in the
body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This role has no built-in drift detection for password aging, empty
  passwords, duplicate UIDs, or `NOPASSWD:ALL` sudoers entries — none of
  that is checked or reported. If that kind of auditing is needed, it has
  to be added to the role first (propose via the branch/PR workflow), not
  assumed to already happen.
- `system_auth_profile_parameters` is a raw string appended to `authselect
  select`, e.g. `with-mkhomedir with-pamaccess` — get this right, a typo'd
  parameter is silently accepted by `authselect` in some cases.
- Sudoers edits made manually (not by this role — this role doesn't touch
  sudoers at all) should always go through `visudo -c`.
