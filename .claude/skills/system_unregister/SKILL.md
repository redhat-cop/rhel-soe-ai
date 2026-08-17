---
name: system_unregister
description: Maintains the ansible/roles/system_unregister Ansible role that unconditionally unregisters a host from Red Hat Insights and Red Hat Subscription Management, as part of the Linux SOE. Use when decommissioning a host or removing it from RHSM/Insights.
---

# system_unregister

Maintains `ansible/roles/system_unregister/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/system_unregister/defaults/main.yml`:

- No configuration variables — running this role always attempts to stop
  `rhcd`, unregister `insights-client`, remove Insights state files, run
  `subscription-manager unregister` + `clean`, and remove any RHSM server
  certs under `/etc/containers/certs.d`.
  Each step is conditioned on the relevant package/state actually being
  present (via `package_facts`), so it's safe to run on a host that's already
  partially or fully unregistered.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/system_unregister`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags system_unregister --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/site.yml --tags system_unregister
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/system_unregister/<short-desc>`, edit `ansible/roles/system_unregister/`, validate
locally (`--syntax-check`, `ansible-lint roles/system_unregister/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[system_unregister] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This is destructive to the host's ability to get RHEL/Satellite content
  until re-registered via `repository_setup` (or manually) — this is a
  decommissioning action, not something to include in a routine SOE
  compliance run. Confirm the host is actually being decommissioned before
  remediating.

## Wiring into the SOE

This role is deliberately **excluded** from `ansible/site.yml`'s default
`roles:` list (see the comment above that list, and the "excluded from the
default run" table in `.claude/skills/soe/SKILL.md`) because it acts
unconditionally with no guard variable and/or reboots, auto-updates, or
de-registers the host outright. It only runs when explicitly invoked with
`--tags system_unregister`, as shown above — never as a side effect of a full SOE
run. Don't add it back to `ansible/site.yml`'s default list without an
explicit decision from a human operator; that would be a cross-cutting,
high-blast-radius change in its own right.
