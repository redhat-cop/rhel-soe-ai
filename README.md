# soe-ai

Experimentation with building a Linux Standard Operating Environment (SOE)
out of specialized AI agents, defined as Claude Code skills. Each skill owns
one configuration domain, and its deliverable is an **Ansible role** that
audits and remediates that domain — instead of one monolithic hardening
script.

There is **no single top-level playbook** that runs every domain. Roles are
triggered through six purpose-scoped playbooks instead — see "Playbook
layout" below.

## Layout

```
ansible/
  configure_rhel.yml         # general host baseline: runs most domain roles
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
  soe/SKILL.md                # orchestrator: which playbook to use for what
  configure_rhel/SKILL.md      # choose which configure_rhel.yml domains apply
  connect_linux/SKILL.md       # pre-flight connectivity/access check
  load_balancer_setup/SKILL.md  # haproxy + keepalived load balancer
  nfs_client_setup/SKILL.md      # NFS client
  nfs_server_setup/SKILL.md       # NFS server
  update_rhel/SKILL.md             # pending-update report + opt-in apply
  <domain>/SKILL.md                 # per-domain: baseline + how to run/extend the role
.github/workflows/
  ansible-ci.yml              # syntax-check + ansible-lint on every PR touching ansible/**
docs/
  ARCHITECTURE.md            # design rationale, audit/remediate conventions, safety rules
```

All 54 domain roles under `ansible/roles/` are fully implemented — real,
idempotent Ansible tasks, not stubs. See `.claude/skills/soe/SKILL.md` for
the full role-to-playbook mapping (which roles are on by default in
`configure_rhel.yml`, which are off by default there, which only run
via a composite playbook, and which aren't wired into any playbook yet).

## Playbook layout

| Playbook | Scope |
|---|---|
| `configure_rhel.yml` | **General host baseline.** Most domain roles are configured here, driven by a `vars:` block in the same file. All 43 in-repo roles it can run are gated by one `configure_rhel_domains` list variable — 20 on by default, 23 more available and fully wired, just off by default. Enable any of them for a run with `-e`, no file edit needed — see `.claude/skills/configure_rhel/SKILL.md`. |
| `connect_linux.yml` | **Pre-flight check.** Confirms SSH reachability and that `become` actually reaches root, before anything else runs. No roles — just ad hoc tasks. Run this first against any host you haven't touched before. |
| `load_balancer_setup.yml` | Configures a host as an haproxy + keepalived load balancer. |
| `nfs_client_setup.yml` | Configures a host as an NFS client (mounts one export). |
| `nfs_server_setup.yml` | Configures a host as an NFS server (exports one directory). |
| `update_rhel.yml` | Reports pending dnf updates by default; applying them is opt-in (commented out). |

A handful of roles — `packages_install`, `files_copy`, `files_create`,
`sebooleans`, `service_state`, `firewall`, `mount_setup` — are **shared
building blocks** reused across more than one of these playbooks, each
time with different variables set directly in that playbook rather than
the role's own `defaults/main.yml`. For example, `packages_install`
installs a general utility package set under `configure_rhel.yml`, but
installs `haproxy`/`keepalived` under `load_balancer_setup.yml`. Always
confirm which playbook actually matches a host's role before running one
of these — see each such role's own `SKILL.md`.

## Audit vs. remediate

Every domain maps onto Ansible's own check mode, so there's no bespoke
report format to maintain:

```sh
# Pre-flight check on an unfamiliar host
ansible-playbook ansible/connect_linux.yml

# Audit (read-only, safe) — general baseline
ansible-playbook ansible/configure_rhel.yml --tags timesync --check --diff

# Remediate (modifies the system)
ansible-playbook ansible/configure_rhel.yml --tags timesync

# Everything active in the baseline at once
ansible-playbook ansible/configure_rhel.yml --check --diff

# A purpose-built playbook instead of the general baseline
ansible-playbook ansible/nfs_client_setup.yml --check --diff
```

See `docs/ARCHITECTURE.md` for why `command`/`shell`-based checks needed
`check_mode: false` to behave correctly under `--check`, and for the
per-role safety conventions (e.g. `usbguard_setup` never enables
enforcement by default until explicitly uncommented — see its `SKILL.md`).

First-class target platform is RHEL-family Linux (RHEL, CentOS Stream,
Fedora).

## How each skill maintains its role

No skill/agent pushes changes to its role directly. Each proposes changes
on a branch (`soe/<domain>/<short-desc>`) and opens a PR
(`[<domain>] <what changed>`) for a human operator to review and merge.
`.github/workflows/ansible-ci.yml` runs `--syntax-check` and `ansible-lint`
on every such PR automatically. See `docs/ARCHITECTURE.md`'s "Contribution
workflow" for the full process.

## Running the agents locally with Claude Code CLI

Each skill under `.claude/skills/` is a project skill — Claude Code CLI
picks them all up automatically the moment you run `claude` inside a clone
of this repo. Nothing needs installing beyond the tools below; there's no
custom MCP server or plugin involved.

### Prerequisites

- **Claude Code CLI**, installed and authenticated
  (`claude login`, or `ANTHROPIC_API_KEY` set).
- **git**, with push access to your fork/remote of this repo.
- **GitHub CLI (`gh`)**, authenticated (`gh auth login`) — Claude uses it to
  open PRs. `git`'s own credentials (SSH key or PAT) are enough for
  `git push`; `gh` is what's used for `gh pr create`.
- **`ansible-core`** (`pip install ansible-core`) so the skills can run
  `ansible-playbook --syntax-check` / `--check --diff` locally before
  proposing a change. `pip install ansible-lint` too, if you want the same
  lint check CI runs.
- **The external collection dependencies** these roles actually call at
  runtime: `ansible-galaxy collection install -r ansible/requirements.yml`.
  Don't separately install this repo's own roles as a collection
  (`myllynen.rhel_ansible_roles`) on a machine you'll also use to run
  these playbooks from the checkout — see `docs/ARCHITECTURE.md`'s
  "Collections vs. local roles" for why that combination silently makes
  `ansible-playbook` ignore local role edits.
- **SSH access** (and sudo/`become` credentials) to whatever hosts you want
  to actually audit/remediate, reachable from wherever you run `claude`.

### 1. Clone and launch

```sh
git clone https://github.com/mglantz/soe-ai.git
cd soe-ai
claude
```

Claude Code loads every `SKILL.md` under `.claude/skills/` as soon as it
starts in this directory — you'll see them listed as available skills.
Add your target hosts to `ansible/inventory/hosts.ini` first (or point at
an inventory elsewhere with `-i`).

### 2. Invoke a skill

Two ways to trigger one, both work:

- **Natural language** — just describe the task and Claude picks the
  matching skill from its description, e.g. *"Audit timesync on
  host1.example.com"*, *"Set up host2 as an NFS server"*, or *"Check the
  general baseline against prod-web-01"* (routes to `soe`, the
  orchestrator, which picks the right playbook for the task).
- **Explicit slash command** — `/timesync`, `/usbguard_setup`,
  `/nfs_server_setup`, `/soe`, etc., if you want to name the skill
  yourself.

Against a host you (or Claude) haven't touched before, it's worth running
`ansible-playbook ansible/connect_linux.yml` first — a fast, read-only
check that SSH and `become` actually work before anything else is
attempted.

A typical baseline audit turn: Claude runs
`ansible-playbook ansible/configure_rhel.yml --tags timesync --check --diff`
against the host(s) you named, then summarizes what's compliant and what's
drifted, in plain language. For a load balancer or NFS host, Claude uses
the matching composite playbook (`load_balancer_setup.yml`,
`nfs_client_setup.yml`, `nfs_server_setup.yml`) instead — see
`.claude/skills/soe/SKILL.md` for the full mapping of which playbook
covers which domain.

### 3. Ask for a fix — role change vs. host remediation

Be explicit about which of these two you mean, since they're different
actions with different approval gates (see `docs/ARCHITECTURE.md`):

- **"Fix the drift on host1"** → Claude re-runs the same
  `ansible-playbook` command without `--check`, applying the existing
  role to that host. Claude will summarize what will change and ask you to
  confirm before running it — this modifies a live system.
- **"Our NTP baseline should point at our internal servers, update the
  role"** → this changes the *role's code*, so Claude follows the branch +
  PR workflow: creates `soe/timesync/<short-desc>`, edits
  `ansible/roles/timesync/`, runs `--syntax-check` and `--check --diff`
  locally, commits, pushes, and opens a PR with `gh pr create` titled
  `[timesync] <what changed>`. Claude does not merge it.

Claude Code will prompt you for permission before it runs `git push` or
`gh pr create` (or any other command it hasn't been pre-approved to run) —
that prompt *is* the local half of the human-in-the-loop design here.
Approving it is what lets the PR go out; there's no separate step to
enable that. Don't blanket-approve `git push`/`gh pr create` in your
Claude Code settings if you want to keep reviewing each one before it
happens.

### 4. Review and merge on GitHub

1. Open the PR Claude created. `.github/workflows/ansible-ci.yml` runs
   `ansible-playbook --syntax-check` and `ansible-lint` automatically —
   check it's green.
2. Read the diff and the `--check --diff` output Claude put in the PR
   body — that's the actual drift/change the role will produce on a real
   host.
3. Approve and merge (or request changes — comment on the PR, then ask
   Claude in the CLI session to address the feedback and push again to
   the same branch).

### 5. Roll the merged change out

Merging the PR only updates the role's code in the default branch — it
doesn't touch any host by itself. After merging, pull `main` and run the
role for real against whichever playbook actually contains it, same as
step 3's "host remediation" case:

```sh
git checkout main && git pull
ansible-playbook ansible/configure_rhel.yml --tags timesync --check --diff   # confirm the diff first
ansible-playbook ansible/configure_rhel.yml --tags timesync                  # then apply
```

Whether that's you running it directly, or asking Claude to run it in a
follow-up turn, is your call either way — it's the same confirm-then-apply
step as any other host remediation.

See `docs/ARCHITECTURE.md` for the full design.
