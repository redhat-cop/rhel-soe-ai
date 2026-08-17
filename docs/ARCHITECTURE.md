# Architecture

soe-ai defines a Linux Standard Operating Environment (SOE) as a set of
independent Claude Code **skills**, one per configuration domain. Each
skill's deliverable is an **Ansible role** under `ansible/roles/<domain>/`
that owns the baseline, drift-checking, and remediation logic for exactly
one part of the system (accounts, time sync, USB policy, etc.). A top-level
`ansible/site.yml` playbook (paired with the `soe` orchestrator skill) runs
all of them and rolls the results into a single compliance run.

## Why skills that output Ansible roles

- Ansible is already the standard way most orgs converge and re-converge
  fleets of RHEL-family hosts — shipping the SOE as roles means it plugs
  directly into existing playbooks, AWX/Ansible Automation Platform, and
  CI, instead of requiring a bespoke runner.
- Each domain's knowledge (which files, which modules, which RHEL tooling)
  stays isolated in its own role directory and is independently testable
  (`ansible-playbook site.yml --tags <domain>`).
- Ansible modules are declarative and (mostly) idempotent by construction,
  so **audit and remediate are the same code path** — see below — instead
  of a separate hand-maintained script per mode.
- New domains are added by adding a new role; `ansible/site.yml` and the
  `soe` skill are the only places that need to know the full list.

## Target platform

First-class support targets RHEL-family systems (RHEL, CentOS Stream,
Fedora) using their native tooling: `dnf`/`package`, `systemd`/`service`,
`chronyd`, `auditd`, `usbguard`, `cronie`. Roles that assume RHEL-family
tooling assert `ansible_os_family == "RedHat"` (see `timesync`) or say so
in an `[INFO]`-style message rather than silently doing the wrong thing on
other distros.

## Layout

```
ansible/
  ansible.cfg
  site.yml                 # top-level playbook: runs every domain role
  inventory/hosts.ini       # sample inventory — add managed hosts here
  roles/
    <domain>/
      defaults/main.yml     # baseline variables — override per host/group
      tasks/main.yml         # enforcement tasks + assert-based drift checks
      handlers/main.yml      # e.g. restart the service a config edit affects
      meta/main.yml           # role metadata
.claude/skills/
  soe/SKILL.md              # orchestrator: how/when to run site.yml
  <domain>/SKILL.md          # per-domain: baseline + how to run/extend the role
.github/workflows/
  ansible-ci.yml            # syntax-check + ansible-lint on every PR touching ansible/**
docs/
  ARCHITECTURE.md            # this file
```

## Audit vs. remediate: `--check --diff` vs. a normal run

Ansible already has a built-in read-only mode, so domain roles don't need a
separate audit script:

- **Audit**: `ansible-playbook site.yml --tags <domain> --check --diff`.
  State-changing modules (`package`, `service`, `lineinfile`, `copy`, ...)
  report what they *would* change without touching the system. `--diff`
  shows the actual before/after content diff.
- **Remediate**: the same command without `--check`. Modules apply the
  change; handlers fire; the role is safe to re-run (idempotent).

One gotcha this repo's roles account for: `command`/`shell` tasks are
**skipped entirely** under `--check` by default, which silently breaks any
`register` → `assert` drift check built on top of one (the registered
result has empty `stdout` in check mode, and the following `assert` then
fails on faked-empty data instead of reporting real state). Every read-only
`command`/`shell` task in this repo's roles is therefore marked
`check_mode: false` so it actually executes and reports real system state
during an audit run — only tasks that *change* the system stay
check-mode-aware (skipped/simulated under `--check`).

Where a module can't declaratively enforce something (e.g. "no duplicate
UIDs" — there's no safe automatic fix), the role reads the current state
with a `command`/`shell` task and reports drift with `ansible.builtin.assert`.
An `assert` failure *is* the audit failure signal — Ansible surfaces it as
a failed task with the `fail_msg` explaining what's wrong, both under
`--check` and a normal run.

## Safety conventions

- Roles never auto-fix by deleting or locking accounts, removing packages,
  or rebooting — see each role's `SKILL.md` for the specific judgment
  calls left to a human (e.g. `accounts_policy` reports `NOPASSWD:ALL`
  sudoers entries but doesn't remove them).
- High-blast-radius changes are opt-in via a role variable, not on by
  default: `usbguard_setup` installs USBGuard and prepares its policy but
  only enables the service when `soe_usbguard_manage_service: true` is set
  explicitly, because a default-block USB policy without a reviewed HID
  allow rule can lock out a physically-connected keyboard/mouse.
- `boot_parameters` is audit-only by design — GRUB command-line edits only
  take effect on next boot and a bad one can leave a host unbootable, so
  this role asserts required/forbidden kernel parameters but leaves the
  actual edit + `grub2-mkconfig` + reboot as a manual, reviewed step.
- Config edits that could break remote access are validated before being
  applied: `motd_issue`'s sshd `Banner` edit runs `sshd -t -f %s` via
  `lineinfile`'s `validate` option before touching `sshd_config`.

## Contribution workflow: branch + PR

No skill pushes directly to the default branch. When a skill's agent needs
to change its role — new baseline check, fixing a bug, responding to drift
it can't auto-remediate safely — the workflow is always propose, not apply
directly:

1. **Branch**: `soe/<domain>/<short-desc>`, e.g. `soe/timesync/add-ptp-check`.
   One domain per branch — don't bundle unrelated roles into the same
   change, so review stays scoped to what one agent actually owns.
2. **Change**: edit `ansible/roles/<domain>/` only (a cross-cutting change
   that touches `ansible/site.yml` or more than one role gets its own
   branch/PR, scoped just to that change).
3. **Validate locally** before opening the PR:
   - `ansible-playbook site.yml --tags <domain> --syntax-check`
   - `ansible-lint roles/<domain>/` (see `.ansible-lint` for this repo's
     one deliberate rule exception, with rationale)
   - `ansible-playbook site.yml --tags <domain> --check --diff` against a
     real or test host if one is available, to see the actual drift/diff
     the change produces
4. **Commit** with a message explaining why, not just what.
5. **Push and open a PR**:
   - Title: `[<domain>] <what changed>`
   - Body: what changed and why, the `--check --diff` output (or a
     summary of it), and any safety notes — new opt-in flags, blast
     radius, anything a reviewer should specifically scrutinize.
6. **Stop.** Do not merge. A human operator reviews and merges. CI
   (`.github/workflows/ansible-ci.yml`) runs `--syntax-check` and
   `ansible-lint` automatically on the PR — treat a CI failure as
   something to fix, not to bypass, and don't merge on its behalf.

This is the same audit/remediate boundary as everywhere else in this repo,
one level up: an agent is free to *read* a host and *propose* a fix, but
applying that fix to shared, versioned automation — like applying a fix to
a live host — needs an explicit human decision.

## Adding a new domain skill

1. `mkdir -p ansible/roles/<domain>/{defaults,tasks,handlers,meta}`
2. Write `defaults/main.yml` (baseline variables, prefixed
   `soe_<domain>_...`) and `tasks/main.yml` (enforcement + `assert` checks),
   following an existing role — `timesync` is the simplest complete example.
3. Add `check_mode: false` to any read-only `command`/`shell` task that
   feeds an `assert`, and `create: true` to any `lineinfile` targeting a
   config file that might not pre-exist on a minimal install.
4. Add the role to the `roles:` list in `ansible/site.yml`.
5. Write `.claude/skills/<domain>/SKILL.md` documenting the baseline and
   how to run the role for audit/remediate, and add a row to the table in
   `.claude/skills/soe/SKILL.md`.
6. Propose all of the above via the branch + PR workflow above — even a
   new domain's first version goes through review, not a direct commit.
