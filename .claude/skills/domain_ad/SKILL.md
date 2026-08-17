---
name: domain_ad
description: Maintains the ansible/roles/domain_ad Ansible role that joins or leaves an Active Directory domain via realmd/adcli and configures sssd/authselect, as part of the Linux SOE. Use when checking or fixing AD domain membership.
---

# domain_ad

Maintains `ansible/roles/domain_ad/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/domain_ad/defaults/main.yml`:

- No-ops entirely unless `domain_ad_domain` is set. `domain_ad_action`
  (`join` or `leave`, default `join`) selects which of `join.yml` / `leave.yml`
  runs after `prepare.yml`.
- `domain_ad_admin_username`/`domain_ad_admin_password` are expected from vault
  (commented out in defaults, not present in plaintext).
- `domain_ad_join_computer_create`/`domain_ad_leave_computer_delete` (both
  default `true`) control whether the AD computer object itself is
  created/deleted by adcli, vs. managed separately.
- `domain_ad_leave_sssd_cache_delete` (default `true`) clears cached users and
  secrets on leave.
- `domain_ad_auth_config_update` (default `true`) runs authselect with
  `domain_ad_auth_select_parameters` (default:
  `without-nullok with-pamaccess with-mkhomedir`) — if `false`, the join is
  left incomplete by design (per the role's own default comment).

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/domain_ad`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags domain_ad --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags domain_ad
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/domain_ad/<short-desc>`, edit `ansible/roles/domain_ad/`, validate
locally (`--syntax-check`, `ansible-lint roles/domain_ad/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[domain_ad] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `domain_ad_admin_password` is a credential — never echo it in a PR body or
  `--check --diff` output; it should come from vault, not `-e` on a shared
  branch.
- Leaving a domain with cache deletion removes cached credentials — confirm
  before remediating a host other admins may also be accessing.

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags domain_ad ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
