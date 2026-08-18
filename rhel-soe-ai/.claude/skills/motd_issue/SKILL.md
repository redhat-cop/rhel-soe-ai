---
name: motd_issue
description: Maintains the ansible/roles/motd_issue Ansible role that deploys /etc/motd (or /etc/motd.d on RHEL 9+) and /etc/issue.d + /etc/issue.net from role-provided templates on RHEL-family systems as part of the Linux SOE. Use when checking or standardizing login banners. Does NOT manage the sshd pre-auth banner.
---

# motd_issue

Maintains `ansible/roles/motd_issue/`. See `docs/ARCHITECTURE.md` for the
shared conventions.

## What the role actually does

Encoded in `ansible/roles/motd_issue/defaults/main.yml` — both variables
are unset by default, so out of the box this role does nothing:

- `issue_template` (if set) → rendered to **both**
  `/etc/issue.d/zz-ansible.issue` and `/etc/issue.net` (the same template,
  same content, two destinations).
- `motd_template` (if set) → rendered to `/etc/motd.d/zz-ansible.motd` on
  RHEL 9+, or directly to `/etc/motd` on RHEL 8.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- motd_issue`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags motd_issue` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags motd_issue --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval.

**Propose a change to the role itself** (e.g. adding the org's approved
banner template): never commit directly. On a branch named
`soe/motd_issue/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/motd_issue/`, `--check --diff`),
push, and open a PR titled `[motd_issue] <what changed>` with the
`--check --diff` output in the body — then stop for human review. See
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- **This role does not touch `sshd_config` or the SSH pre-auth banner.**
  If the org needs the SSH pre-auth banner (`Banner` directive) to match
  `/etc/issue.net`, that's a gap in the role today, not something already
  handled — flag it rather than assuming it's covered.
- Neither `motd_template` nor `issue_template` has role-provided
  alternatives shipped in `files/`/`templates/` (unlike `accounts_policy`
  or `audit_setup`) — the org's banner content has to be supplied
  entirely externally (a template path outside this role, or a new file
  added to the role first).
- If the approved banner text is supplied, avoid `\v`/`\r`/`\m`/`\s`
  escape sequences in the issue content — those leak kernel/OS version to
  an unauthenticated user at the pre-auth banner (this is a property of
  `/etc/issue`/`/etc/issue.net` content itself, not something the role
  enforces).
