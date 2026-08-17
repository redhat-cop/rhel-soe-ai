---
name: repository_setup
description: Maintains the ansible/roles/repository_setup Ansible role that manages yum.repos.d files and Red Hat Subscription Management (RHSM) registration/repo enablement, as part of the Linux SOE. Use when checking or fixing repo files, RHSM subscription state, or enabled/disabled RHSM repo IDs.
---

# repository_setup

Maintains `ansible/roles/repository_setup/`. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules, branch + PR contribution workflow).

## What the role actually does

Encoded in `ansible/roles/repository_setup/defaults/main.yml`:

- `repository_setup_repo_files_copy`/`repository_setup_repo_files_remove`
  (both default empty) manage arbitrary files under `/etc/yum.repos.d`.
- `repository_setup_rhsm_configure` (default `true`) gates everything RHSM
  below it — set `false` to have this role only touch repo files.
- `repository_setup_rhsm_subscribe` (default `true`) toggles subscribe vs.
  unsubscribe intent; `repository_setup_rhsm_parameters` maps directly onto
  `community.general.redhat_subscription`'s parameters (activationkey/org_id
  or username/password — from vault — left undefined skips RHSM entirely).
- `repository_setup_rhsm_curl_args` — if set, bypasses the parameter-based
  registration and uses a raw curl command instead (the parameters above are
  then ignored).
- `repository_setup_install_katello_rpm` (default `true`) installs the
  Satellite `katello-ca-consumer-latest.rpm`.
- `repository_setup_rhsm_repositories_enable`/`_disable` manage specific repo
  IDs; `repository_setup_rhsm_repositories_purge` (default `true`) disables
  any RHSM repo not explicitly enabled.

This role is sourced from the myllynen/rhel-ansible-roles import
(see `git log -- ansible/roles/repository_setup`) rather than hand-authored for this
repo. Unlike the original reference domains (e.g. `timesync`, `usbguard_setup`),
it applies state declaratively via standard Ansible modules and does **not**
add its own `assert`-based drift checks on top — an audit here is exactly
what `--check --diff` reports from the underlying modules, nothing more.

## What to do

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- repository_setup`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags repository_setup` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

**Audit** (read-only, safe to run any time):

```
ansible-playbook ansible/configure_rhel.yml --tags repository_setup --check --diff
```

Summarize the diff output and any failed tasks in plain language.

**Remediate** (modifies the system — only after the user explicitly asks):
first summarize what will change from the `--check --diff` output, then run
the same command without `--check`:

```
ansible-playbook ansible/configure_rhel.yml --tags repository_setup
```

**Propose a change to the role itself**: never edit and commit directly. On a
branch named `soe/repository_setup/<short-desc>`, edit `ansible/roles/repository_setup/`, validate
locally (`--syntax-check`, `ansible-lint roles/repository_setup/`, and
`--check --diff` against a real/test host if available), then push and open a
PR titled `[repository_setup] <what changed>` with the `--check --diff` output in the
body. Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- `repository_setup_rhsm_parameters.password`/activation key material is a
  credential — vault it, never put it in a PR body or `-e` on a shared branch.
- `repository_setup_rhsm_repositories_purge: true` (the default) disables any
  repo not in the enable list — confirm the enable list is complete before
  remediating a host that depends on additional repos.

## Wiring into the SOE

This role has a row in `.claude/skills/soe/SKILL.md`'s domain table, but is
**commented out** in `ansible/configure_rhel.yml`'s `roles:` list by default
(`#- repository_setup`) — see the caveat at the top of "What to do" above. It is not
referenced by any of the other playbooks (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, `update_rhel.yml`,
`connect_linux.yml`) either. This repo no longer uses `ansible/site.yml`; see
`docs/ARCHITECTURE.md`.
