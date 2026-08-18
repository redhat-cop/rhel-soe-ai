---
name: performance_tuning
description: Maintains the ansible/roles/performance_tuning Ansible role that sets the active tuned profile, as part of the Linux SOE. Use when checking or fixing the system's tuned performance profile.
---

# performance_tuning

Maintains `ansible/roles/performance_tuning/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

`ansible/roles/performance_tuning/README.md` documents this role's full
configuration surface (every `defaults/main.yml` variable, with its
original inline comments, rendered as a single reference). Read it
before proposing or explaining how to configure this role — it
reflects the role's actual current defaults even if a variable summary
elsewhere in this file has drifted out of sync with the role.

## What the role actually does

Encoded in `ansible/roles/performance_tuning/defaults/main.yml`:

- Single variable, `tuned_profile`, defaults to `virtual-guest` when
  `ansible_facts.virtualization_role == 'guest'`, else `throughput-performance`
  — the default already branches per host, not a single fixed value.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/performance_tuning`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags performance_tuning --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags performance_tuning
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/performance_tuning/<short-desc>`, edit `ansible/roles/performance_tuning/`, validate
locally (`--syntax-check`, `ansible-lint roles/performance_tuning/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[performance_tuning] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is in `configure_rhel_domains`'s default value in
`ansible/configure_rhel.yml` (see `.claude/skills/configure_rhel/SKILL.md`)
and has a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as
part of both `ansible-playbook ansible/configure_rhel.yml --tags performance_tuning ...` and
a full, untagged `ansible-playbook ansible/configure_rhel.yml` run. This repo
no longer uses `ansible/site.yml` as the baseline entrypoint — see
`docs/ARCHITECTURE.md`.
