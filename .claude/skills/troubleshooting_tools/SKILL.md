---
name: troubleshooting_tools
description: Maintains the ansible/roles/troubleshooting_tools Ansible role that installs a baseline set of diagnostic packages and optionally enables PCP performance-metrics collection on RHEL-family systems as part of the Linux SOE. Use when checking whether standard diagnostic tools (sos, tcpdump, strace, lsof, bind-utils, pcp-system-tools) are present.
---

# troubleshooting_tools

Maintains `ansible/roles/troubleshooting_tools/`. See
`docs/ARCHITECTURE.md` for the shared conventions.

## What the role actually does

Encoded in `ansible/roles/troubleshooting_tools/defaults/main.yml`
(`troubleshooting_tools` — adjust to the org's actual list before relying
on this): `bind-utils`, `curl`, `ethtool`, `iotop`, `iproute`, `lsof`,
`man-pages`, `pcp-system-tools`, `policycoreutils-python-utils`,
`procps-ng`, `psmisc`, `sos`, `strace`, `sysstat`, `tcpdump`, `time` —
plus several commented-out optional entries (`ltrace`, `numactl`, `perf`,
`setroubleshoot-server`) the org can uncomment.

- Installs the full `troubleshooting_tools` list via `dnf` — every run,
  unconditionally, no missing/present comparison message beforehand (the
  `dnf` module's own idempotency and `--diff` output is the only
  visibility into what's missing).
- If `troubleshooting_tools_enable_perf_metrics: true` (default) **and**
  `pcp-system-tools` is both in the list and actually installed, enables
  and starts `pmcd` and `pmlogger` (PCP metrics collection + archiving).

## What to do

> **This role is off by default** in `ansible/configure_rhel.yml` — every
> role there (active or not) is gated by a single `configure_rhel_domains`
> list variable (`when: "'<name>' in configure_rhel_domains"`), and `troubleshooting_tools`
> isn't in the default value of that list. Nothing needs editing in the
> playbook itself to turn it on: pass the *full* desired domain list via
> `-e`, e.g.
> `-e '{"configure_rhel_domains": [...the default 20..., "troubleshooting_tools"]}'`
> (see `.claude/skills/configure_rhel/SKILL.md` for the current default list
> to extend, and why it has to be the full list, not just the addition —
> `-e` replaces the variable's value, it doesn't merge into it). `--tags troubleshooting_tools`
> alone is **not** enough — the domains list and `--tags`/`--skip-tags` are
> separate, ANDed gates, both verified independently: a role only runs if
> it's in `configure_rhel_domains` *and* matches the requested tags. Some
> roles (this one — check its `defaults/main.yml` and task file) also have
> their own internal enable flag or required variable on top of that, which
> still needs setting the same as before. Flag all of this to the user before
> assuming the commands below will do anything.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags troubleshooting_tools --check --diff`.
Read the `dnf` task's own `--diff` output for which packages are
missing — there's no separate "Missing baseline packages: ..." summary
message; the module's diff output is the source of truth.

**Remediate**: same command without `--check`, after explicit user
approval — this only *installs* missing baseline packages, it never
removes anything.

**Propose a change to the role itself** (e.g. adding/removing a package
from the baseline, or toggling the PCP default): never commit directly.
On a branch named `soe/troubleshooting_tools/<short-desc>`, edit the
role, validate locally (`--syntax-check`,
`ansible-lint roles/troubleshooting_tools/`, `--check --diff`), push, and
open a PR titled `[troubleshooting_tools] <what changed>` with the
`--check --diff` output in the body — then stop for human review. See
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- This is a one-directional check: packages **missing** from the baseline
  are installed. Packages **outside** the baseline (installed ad hoc, e.g.
  `wireshark`) are not reported or touched by this role.
- `troubleshooting_tools_enable_perf_metrics` only takes effect if
  `pcp-system-tools` is actually in the `troubleshooting_tools` list —
  removing that package from the baseline silently disables PCP
  enablement too, since the `pcp` fact check gates on it having been
  installed.
