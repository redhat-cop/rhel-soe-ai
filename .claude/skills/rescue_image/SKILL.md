---
name: rescue_image
description: Maintains the ansible/roles/rescue_image Ansible role that enables or disables kernel rescue image generation, as part of the Linux SOE. Use when checking or fixing whether a rescue image is (re)built on kernel install.
---

# rescue_image

Maintains `ansible/roles/rescue_image/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/rescue_image/defaults/main.yml`:

- Single variable, `rescue_image_enable` (default `false`). The role's own
  note: rescue images are (re)built on the *next* kernel install, not
  immediately by this role — so `--check --diff` reporting no drift doesn't
  mean a rescue image already exists for the current kernel.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/rescue_image`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags rescue_image --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags rescue_image
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/rescue_image/<short-desc>`, edit `ansible/roles/rescue_image/`, validate
locally (`--syntax-check`, `ansible-lint roles/rescue_image/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[rescue_image] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Wiring into the SOE

This role is included in `ansible/site.yml`'s default `roles:` list and has
a row in `.claude/skills/soe/SKILL.md`'s domain table, so it runs as part of
both `ansible-playbook ansible/site.yml --tags rescue_image ...` and a full,
untagged `ansible-playbook ansible/site.yml` run.
