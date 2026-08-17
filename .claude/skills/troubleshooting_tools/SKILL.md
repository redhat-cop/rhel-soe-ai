---
name: troubleshooting_tools
description: Maintains the ansible/roles/troubleshooting_tools Ansible role that audits and remediates the baseline set of troubleshooting/diagnostic packages installed on RHEL-family systems as part of the Linux SOE. Use when checking whether standard diagnostic tools (sos, tcpdump, strace, lsof, bind-utils) are present.
---

# troubleshooting_tools

Maintains `ansible/roles/troubleshooting_tools/`. See
`docs/ARCHITECTURE.md` for the shared conventions.

## Baseline

Encoded in `ansible/roles/troubleshooting_tools/defaults/main.yml`
(`soe_troubleshooting_packages`, adjust to the org's actual list before
relying on this): `sos`, `tcpdump`, `strace`, `lsof`, `bind-utils`,
`nmap-ncat`, `iotop`.

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags troubleshooting_tools --check --diff`.
The role gathers package facts and reports an explicit
`Missing baseline troubleshooting packages: ...` (or `All baseline
troubleshooting packages are present: ...`) message before the install
task's own `--diff` output, so compliance status is visible even without
reading the diff.

**Remediate**: same command without `--check`, after explicit user
approval — this only *installs* missing baseline packages, it never
removes anything (see Notes).

**Propose a change to the role itself** (e.g. adding/removing a package
from the baseline): never commit directly. On a branch named
`soe/troubleshooting_tools/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/troubleshooting_tools/`,
`--check --diff`), push, and open a PR titled
`[troubleshooting_tools] <what changed>` with the `--check --diff` output
in the body — then stop for human review. See `docs/ARCHITECTURE.md`'s
"Contribution workflow".

## Notes

- This is a one-directional check: packages **missing** from the baseline
  are installed. Packages **outside** the baseline (installed ad hoc, e.g.
  `wireshark`) are not reported or touched by this role — removing a
  package a human installed for a reason is a judgment call, not something
  to automate.
