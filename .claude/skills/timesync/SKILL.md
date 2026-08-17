---
name: timesync
description: Maintains the ansible/roles/timesync Ansible role that audits and remediates time synchronization (chronyd) on RHEL-family systems as part of the Linux SOE. Use when checking, configuring, or fixing NTP/chrony time sync, clock drift, or "system clock not synchronized" issues.
---

# timesync

Reference implementation for a domain skill in the SOE. This skill's
deliverable is `ansible/roles/timesync/` — other domain skills in this repo
follow the same pattern. See `docs/ARCHITECTURE.md` for the shared
conventions (role layout, audit vs. remediate via `--check --diff`, safety
rules).

## Baseline

Encoded in `ansible/roles/timesync/defaults/main.yml`:

- `chrony` package installed.
- `chronyd.service` enabled and active.
- `/etc/chrony.conf` defines at least one `pool` line
  (`soe_timesync_pools`, default `2.rhel.pool.ntp.org iburst`).
- The system clock is actually synchronized (checked via
  `timedatectl show --property=NTPSynchronized --value`, not just "chronyd
  is running").

## What to do

**To audit** (read-only, safe to run any time):

```
ansible-playbook ansible/site.yml --tags timesync --check --diff
```

Summarize the diff output and any failed `assert` tasks in plain language.
A clean run (no diffs, no failed asserts) means the host is compliant.

**To remediate** (modifies the system — only after the user explicitly
asks for the fix to be applied, not just the audit): first summarize what
will change (from the `--check --diff` output), then run the same command
without `--check`:

```
ansible-playbook ansible/site.yml --tags timesync
```

**To propose a change to the role itself** (new baseline check, bug fix,
new default): never edit and commit directly. On a branch named
`soe/timesync/<short-desc>`, edit `ansible/roles/timesync/tasks/main.yml`
and `defaults/main.yml`, validate locally
(`--syntax-check`, `ansible-lint roles/timesync/`, and `--check --diff`
against a real/test host if available), then push and open a PR titled
`[timesync] <what changed>` with the `--check --diff` output in the body.
Then stop — a human reviews and merges; see `docs/ARCHITECTURE.md`'s
"Contribution workflow" for the full process. If you add a `command`/`shell`
task that feeds an `assert`, mark it `check_mode: false` (see
`docs/ARCHITECTURE.md`'s "Audit vs. remediate" section) or it will silently
report false drift under `--check`.

## Notes

- The role asserts `ansible_os_family == "RedHat"` up front; on other
  distros it fails loudly rather than silently checking the wrong config
  path (Debian uses `/etc/chrony/chrony.conf`, not `/etc/chrony.conf`).
- `soe_timesync_pools` defaults to a placeholder public pool; point it at
  the org's own internal NTP servers via `group_vars`/`host_vars` or
  `-e` if it has them.
