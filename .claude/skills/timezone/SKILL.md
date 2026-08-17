---
name: timezone
description: Maintains the ansible/roles/timezone Ansible role that audits and remediates the system timezone on RHEL-family systems as part of the Linux SOE. Use when checking or setting the timezone via timedatectl.
---

# timezone

Maintains `ansible/roles/timezone/`. See `docs/ARCHITECTURE.md` for the
shared conventions. Closely related to `timesync` (both affect what time
the system reports) but kept as a separate role since timezone is a policy
choice, not a sync-health check.

## Baseline

Encoded in `ansible/roles/timezone/defaults/main.yml`:

- `soe_timezone` (default `UTC` — org policy: servers generally standardize
  on UTC, but confirm with the user before assuming) is a valid IANA zone
  per `timedatectl list-timezones`.
- `timedatectl show --property=Timezone --value` matches `soe_timezone`.

## What to do

**Audit**: `ansible-playbook ansible/site.yml --tags timezone --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval. Applies via `timedatectl set-timezone`, not by re-linking
`/etc/localtime` by hand.

**Propose a change to the role itself** (e.g. changing the default
timezone policy): never commit directly. On a branch named
`soe/timezone/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/timezone/`, `--check --diff`), push,
and open a PR titled `[timezone] <what changed>` with the `--check --diff`
output in the body — then stop for human review. See
`docs/ARCHITECTURE.md`'s "Contribution workflow".
