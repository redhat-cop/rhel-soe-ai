---
name: motd_issue
description: Maintains the ansible/roles/motd_issue Ansible role that audits and remediates /etc/motd and /etc/issue* banner files (plus the sshd pre-auth banner) on RHEL-family systems as part of the Linux SOE. Use when checking or standardizing login banners or checking for information disclosure in pre-auth banners.
---

# motd_issue

Maintains `ansible/roles/motd_issue/`. See `docs/ARCHITECTURE.md` for the
shared conventions.

## Baseline

Encoded in `ansible/roles/motd_issue/defaults/main.yml`:

- `/etc/motd`, `/etc/issue`, `/etc/issue.net` all match the org's approved
  banner text (`soe_motd_content` / `soe_issue_content`), mode `0644`,
  owned `root:root`.
- If `soe_sshd_manage_banner` is true (default), `sshd_config` has
  `Banner /etc/issue.net` set so the SSH pre-auth banner matches too.

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags motd_issue --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval.

**Propose a change to the role itself** (e.g. updating the approved banner
text): never commit directly. On a branch named
`soe/motd_issue/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/motd_issue/`, `--check --diff`),
push, and open a PR titled `[motd_issue] <what changed>` with the
`--check --diff` output in the body — then stop for human review. See
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- The default banner text is a placeholder — replace
  `soe_motd_content`/`soe_issue_content` with the org's actual approved
  legal/warning banner before relying on this role.
- The approved banner should not contain systemd's `\v`/`\r`/`\m`/`\s`
  escape sequences in `/etc/issue`/`/etc/issue.net` — those leak
  kernel/OS version to an unauthenticated user at the pre-auth banner.
- The sshd `Banner` edit is applied via `lineinfile`'s `validate: sshd -t
  -f %s`, so a malformed result is rejected before it's written — an
  invalid `sshd_config` can lock out remote access, so this is validated
  before being applied, not after.
