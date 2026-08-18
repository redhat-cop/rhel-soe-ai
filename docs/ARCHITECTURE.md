# Architecture

soe-ai defines a Linux Standard Operating Environment (SOE) as a set of
independent Claude Code **skills**, one per configuration domain. Each
skill's deliverable is an **Ansible role** under `ansible/roles/<domain>/`
that owns the baseline, drift-checking, and remediation logic for exactly
one part of the system (accounts, time sync, USB policy, etc.). Rather than
one top-level playbook running every domain role unconditionally, the roles
are wired into **six purpose-scoped playbooks** — see "Playbook layout"
below — and the `soe` orchestrator skill knows which playbook to use for a
given task.

## Why skills that output Ansible roles

- Ansible is already the standard way most orgs converge and re-converge
  fleets of RHEL-family hosts — shipping the SOE as roles means it plugs
  directly into existing playbooks, AWX/Ansible Automation Platform, and
  CI, instead of requiring a bespoke runner.
- Each domain's knowledge (which files, which modules, which RHEL tooling)
  stays isolated in its own role directory and is independently testable
  (`ansible-playbook configure_rhel.yml --tags <domain>`, or whichever
  playbook actually wires that role in — see below).
- Ansible modules are declarative and (mostly) idempotent by construction,
  so **audit and remediate are the same code path** — see below — instead
  of a separate hand-maintained script per mode.
- New domains are added by adding a new role; whichever playbook(s) should
  trigger it, and the `soe` skill, are the only other places that need to
  know about it.

## Playbook layout

This repo does **not** use a single `ansible/site.yml` covering every
domain. Instead:

| Playbook | Scope |
|---|---|
| `configure_rhel.yml` | General host baseline — most domain roles live here, driven by a `vars:` block in the same file rather than each role's own `defaults/`. All 43 in-repo roles it can run are gated by a single `configure_rhel_domains` list variable rather than being commented in/out of the file — see `.claude/skills/configure_rhel/SKILL.md`. |
| `connect_linux.yml` | Pre-flight connectivity/access check — no roles, just ad hoc tasks confirming SSH reachability and `become`. |
| `load_balancer_setup.yml` | Configures a host as an haproxy + keepalived load balancer, reusing generic roles (`packages_install`, `files_copy`, `sebooleans`, `service_state`) with load-balancer-specific variables. |
| `nfs_client_setup.yml` | Configures a host as an NFS client, reusing `packages_install`, `files_create`, `service_state`, `mount_setup`. |
| `nfs_server_setup.yml` | Configures a host as an NFS server, reusing `packages_install`, `files_create`, `files_copy`, `sebooleans`, `firewall`, `service_state`. |
| `update_rhel.yml` | Reports (and, opt-in, applies) pending dnf updates. |

A handful of roles — `packages_install`, `files_copy`, `files_create`,
`sebooleans`, `service_state`, `firewall`, `mount_setup` — are **shared
building blocks**: the same role directory is invoked by more than one
playbook above, each time with different variables set directly in that
playbook rather than the role's own `defaults/main.yml`. That's a
deliberate reuse pattern (why re-implement "install a package list" or
"copy a file" per scenario?), not duplication to clean up — but it does
mean "is `packages_install` compliant?" is a question that only makes
sense against one specific playbook at a time, not the role in the
abstract. See `.claude/skills/soe/SKILL.md` for the full role-to-playbook
mapping, including which roles are off by default within
`configure_rhel.yml` and which aren't wired into any playbook at all yet.

Every role entry in all five role-bearing playbooks also carries an
explicit `tags: ["<name>"]`, so `--tags <domain>` reliably selects just
that role. This needed fixing directly: a bare role name in a `roles:`
list gets no implicit tag matching its own name, so `--tags <domain>`
previously matched nothing anywhere in this repo regardless of what any
`SKILL.md` claimed — confirmed by testing against the actual, unmodified
`main` branch, not assumed from reading the YAML.

## Collections vs. local roles

This repo's `ansible/galaxy.yml` declares this content as an installable
collection under the identity `myllynen.rhel_ansible_roles` — the same
identity as the actual upstream repo (`myllynen/rhel-ansible-roles`) these
roles were originally bulk-imported from. That identity is unchanged by
design; don't rename it without a deliberate, separate decision, since
other consumers may already reference roles by that FQCN.

That shared identity has a real consequence for local development,
confirmed by testing: **when a play declares a `collections:` keyword
naming a collection, Ansible resolves bare role names against that
collection *before* `roles_path` or a playbook-adjacent `roles/`
directory** — not as a fallback if local resolution fails, but
unconditionally, for every bare role name in that play, including ones
reached indirectly via `include_role`/`import_role` from inside another
role. If `myllynen.rhel_ansible_roles` happens to be installed on the
machine running `ansible-playbook` (e.g. because it was manually installed
as a collection, or `-r requirements.yml` was run against a version of
that file that named this repo as a dependency), a play that declares
`collections: [myllynen.rhel_ansible_roles]` will silently run the
*installed* copy of a role instead of the one sitting in
`ansible/roles/<domain>/` right next to the playbook — with no error and
no indication anything was skipped. A role a Claude Code skill just edited
would appear to validate cleanly under `--check --diff` while actually
exercising old, previously-installed code; after merge, nothing about
running the playbook again from `main` would pick up the change either,
since the installed collection was never consulted in the first place.

Because of this, `configure_rhel.yml`, `load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`, and `update_rhel.yml`
**do not** declare a play-level `collections:` keyword for
`myllynen.rhel_ansible_roles`. Bare role names in these playbooks — both
the top-level `roles:` list and any role-calling-role `include_role`
inside them (e.g. `audit_setup`/`certificates`/`sshd_configuration`/
`usbguard_setup` each pull in `files_remove` this way) — always resolve
via `ansible.cfg`'s `roles_path`, i.e. the checkout's own
`ansible/roles/`, regardless of whether `myllynen.rhel_ansible_roles`
happens to be installed on the machine. This was verified directly: the
same role name present both locally and in an installed collection
resolves to the local copy with the `collections:` keyword absent, and to
the installed copy with it present — with everything else held constant.

The one legitimate use of an external collection role in this repo is
`timesync`'s `include_role: name: redhat.rhel_system_roles.timesync` — a
**fully-qualified** name (`namespace.collection.role`), which resolves
directly to whatever collection provides it and was never affected by the
play-level `collections:` keyword either way. `ansible/requirements.yml`
lists the actual external collections these roles depend on at runtime —
`ansible.posix`, `community.general`, `redhat.rhel_system_roles` —
install with `ansible-galaxy collection install -r requirements.yml`.
It deliberately does **not** list `myllynen.rhel_ansible_roles` (or this
repo itself) as a dependency, for the reason above.

If something outside this repo does need to consume these roles via their
collection identity directly (e.g. a separate playbook elsewhere written
against `myllynen.rhel_ansible_roles.<role>` FQCNs), installing this repo
as that collection is still supported —
`ansible-galaxy collection install git+https://github.com/redhat-cop/rhel-soe-ai,main`
works and installs under that identity, same as before. Just know that
doing so on a machine that also runs this repo's own six playbooks now has
no effect on them one way or the other (by design, per above) — and that
collections are static snapshots: merging a role change to `main` doesn't
update an already-installed collection copy anywhere it's in use. Picking
up a merged change through that path means re-running the install command
with `--force` (plain reinstall can no-op, since `galaxy.yml` pins a
static `version: "3.4.10"` that Galaxy may consider already satisfied
regardless of how far `main` has moved).

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
  configure_rhel.yml         # general host baseline playbook
  connect_linux.yml           # pre-flight connectivity/access check (no roles)
  load_balancer_setup.yml      # haproxy + keepalived load balancer
  nfs_client_setup.yml          # NFS client (mounts one export)
  nfs_server_setup.yml           # NFS server (exports one directory)
  update_rhel.yml                 # pending-update report (+ opt-in apply)
  inventory/hosts.ini               # sample inventory — add managed hosts here
  roles/
    <domain>/
      defaults/main.yml     # baseline variables — override per host/group
      tasks/main.yml         # enforcement tasks + assert-based drift checks
      handlers/main.yml      # e.g. restart the service a config edit affects
      meta/main.yml           # role metadata
.claude/skills/
  soe/SKILL.md              # orchestrator: which playbook to use for what
  <domain>/SKILL.md          # per-domain: baseline + how to run/extend the role
.github/workflows/
  ansible-ci.yml            # syntax-check + ansible-lint on every PR touching ansible/**
docs/
  ARCHITECTURE.md            # this file
```

## Audit vs. remediate: `--check --diff` vs. a normal run

Ansible already has a built-in read-only mode, so domain roles don't need a
separate audit script:

- **Audit**: `ansible-playbook <playbook>.yml --tags <domain> --check --diff`,
  using whichever playbook from the table above actually contains that
  role. State-changing modules (`package`, `service`, `lineinfile`,
  `copy`, ...) report what they *would* change without touching the
  system. `--diff` shows the actual before/after content diff.
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
- High-blast-radius changes get an extra layer of friction beyond a role
  variable, not just a variable default: `usbguard_setup` defaults to
  `usbguard_setup_policy: reject` — enforcement, not merely installed —
  the moment the role actually runs, with no separate "enable the
  service" flag to opt into first. Because of that, the real safety net
  here is `configure_rhel_domains` (see
  `.claude/skills/configure_rhel/SKILL.md`): `usbguard_setup` is off by
  default in `configure_rhel.yml`, so it takes a deliberate `-e` on a
  specific run, or a deliberate change to the default list via the
  branch + PR workflow, before enforcement can start — not a role
  variable a host's group_vars might set without anyone noticing.
- `boot_parameters` is audit-only by design — GRUB command-line edits only
  take effect on next boot and a bad one can leave a host unbootable, so
  this role asserts required/forbidden kernel parameters but leaves the
  actual edit + `grub2-mkconfig` + reboot as a manual, reviewed step.
- Config edits that could break remote access are validated before being
  applied: `motd_issue`'s sshd `Banner` edit runs `sshd -t -f %s` via
  `lineinfile`'s `validate` option before touching `sshd_config`.
- **A role being off by default in `configure_rhel_domains` is itself a
  safety convention**, not just an unused-feature marker:
  `configure_rhel.yml` keeps 23 roles present-but-off specifically so a
  plain, untagged run of the baseline playbook doesn't silently pick up
  something high-blast-radius (account deletion, USB lockdown, AD domain
  join) that a host's group_vars haven't been reviewed for yet. Don't
  "clean up" by adding every available domain to the default list at
  once — add one domain for one host or group, deliberately, per the
  branch + PR workflow below. One exception worth flagging: `system_init`
  *is* in the default list in `configure_rhel.yml` even though it reboots
  the host by default — see that role's `SKILL.md`.

## Contribution workflow: branch + PR

No skill pushes directly to the default branch. When a skill's agent needs
to change its role — new baseline check, fixing a bug, responding to drift
it can't auto-remediate safely — the workflow is always propose, not apply
directly:

1. **Branch**: `soe/<domain>/<short-desc>`, e.g. `soe/timesync/add-ptp-check`.
   One domain per branch — don't bundle unrelated roles into the same
   change, so review stays scoped to what one agent actually owns.
2. **Change**: edit `ansible/roles/<domain>/` only (a cross-cutting change
   that touches one of the top-level playbooks or more than one role gets
   its own branch/PR, scoped just to that change).
3. **Validate locally** before opening the PR, against whichever
   playbook(s) actually contain the role (see
   `.claude/skills/soe/SKILL.md`'s tables):
   - `ansible-playbook <playbook>.yml --tags <domain> --syntax-check`
   - `ansible-lint roles/<domain>/` (see `.ansible-lint` for this repo's
     one deliberate rule exception, with rationale)
   - `ansible-playbook <playbook>.yml --tags <domain> --check --diff` against a
     real or test host if one is available, to see the actual drift/diff
     the change produces

   These playbooks resolve roles from the checkout's own `ansible/roles/`
   regardless of whether `myllynen.rhel_ansible_roles` is also installed
   as a collection on the machine — see "Collections vs. local roles"
   above for why that matters here specifically: it's what makes this
   validation step trustworthy in the first place.
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
4. Decide where the role belongs and wire it in accordingly:
   - General host baseline → add a `- role: <name> / tags: ["<name>"] /
     when: "'<name>' in configure_rhel_domains"` entry to
     `ansible/configure_rhel.yml`'s `roles:` list, with a matching
     `vars:` entry, and decide whether it belongs in the default
     `configure_rhel_domains` value (active by default) or not
     (high-blast-radius/opt-in) — see
     `.claude/skills/configure_rhel/SKILL.md`.
   - A specific host purpose (load balancer, NFS client/server, update
     run) → add it to the matching existing playbook, or propose a new
     purpose-scoped playbook following the same shape (a `vars:` block
     plus a short `roles:` list) if none of the existing ones fit.
5. Write `.claude/skills/<domain>/SKILL.md` documenting the baseline and
   how to run the role for audit/remediate against whichever playbook(s)
   now contain it, and add a row to the appropriate table in
   `.claude/skills/soe/SKILL.md`.
6. Propose all of the above via the branch + PR workflow above — even a
   new domain's first version goes through review, not a direct commit.
