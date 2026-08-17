---
name: timezone
description: Maintains the ansible/roles/timezone Ansible role that sets the system timezone via community.general.timezone, as part of the Linux SOE. Use when checking or fixing the system timezone. Note: soe/SKILL.md currently states there is no timezone role in this repo — that note is stale as of this role's addition and should be corrected (see Notes).
---

# timezone

Maintains `ansible/roles/timezone/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/timezone/defaults/main.yml`:

- Single variable, `timezone`, default `UTC`.
- Depends on the `community.general` collection (`community.general.timezone`)
  being installed, same external-dependency caveat as `timesync`'s reliance on
  `redhat.rhel_system_roles`.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/timezone`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags timezone --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags timezone
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/timezone/<short-desc>`, edit `ansible/roles/timezone/`, validate
locally (`--syntax-check`, `ansible-lint roles/timezone/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[timezone] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `docs/ARCHITECTURE.md`'s "Adding a new domain skill" step 4 and this
  role's own presence mean `ansible/site.yml` and the table in
  `.claude/skills/soe/SKILL.md` should both be updated to include `timezone`
  (git history shows a `timezone` role was previously removed and its skill
  deleted, then re-added in bulk with the other myllynen-sourced roles —
  the removal note in `soe/SKILL.md` predates this re-add and is now
  inaccurate).

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags timezone ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
