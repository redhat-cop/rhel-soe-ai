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

> **This role is currently commented out** in `ansible/configure_rhel.yml`'s `roles:` list (`#- troubleshooting_tools`) and its associated
> `vars:` block is left at placeholder/empty values. `--tags troubleshooting_tools` will report
> "did not match any tags" until a human operator uncomments the role (and
> fills in the vars it needs) in `ansible/configure_rhel.yml` — this is a
> deliberate, host-baseline-scoped opt-in, not a bug. Flag this to the user
> before assuming the commands below will do anything.

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
