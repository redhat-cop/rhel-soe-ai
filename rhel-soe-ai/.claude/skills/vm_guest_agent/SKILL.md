---
name: vm_guest_agent
description: Maintains the ansible/roles/vm_guest_agent Ansible role that detects the hypervisor a system runs under and installs/enables the matching guest agent (qemu-guest-agent, open-vm-tools, hyperv-daemons) as part of the Linux SOE. Use when checking guest-agent presence or state on a virtual machine.
---

# vm_guest_agent

Maintains `ansible/roles/vm_guest_agent/`. See `docs/ARCHITECTURE.md` for
the shared conventions. Unlike most domains, this role branches on detected
virtualization type rather than checking one fixed baseline.

## Baseline

Encoded in `ansible/roles/vm_guest_agent/defaults/main.yml`
(`soe_vm_guest_agent_map`), keyed by `systemd-detect-virt` output:

- `kvm` → `qemu-guest-agent` package + `qemu-guest-agent.service`
- `vmware` → `open-vm-tools` package + `vmtoolsd.service`
- `microsoft` → `hyperv-daemons` package + `hypervkvpd.service`
- `none` (bare metal) → no agent expected, reported as `[INFO]`
- Anything else (e.g. a public cloud platform) → reported as `[INFO]`,
  deferring to that provider's own guest-agent/cloud-init guidance rather
  than guessing

## What to do

> **Known naming mismatch** (pre-existing, not introduced by this change):
> the actual role directory and the tag used by `configure_rhel.yml`'s
> `roles:` list are both `guest_agent`, not `vm_guest_agent` — see
> `.claude/skills/guest_agent/SKILL.md` and the note in
> `.claude/skills/soe/SKILL.md`'s domain table ("role dir is `guest_agent`,
> not `vm_guest_agent`"). `--tags vm_guest_agent` will report "did not
> match any tags" against every playbook in this repo. Use `--tags
> guest_agent` (see that skill) until this mismatch is resolved, or flag it
> to a human operator as something worth fixing via the branch + PR
> workflow.

**Audit**: `ansible-playbook ansible/configure_rhel.yml --tags guest_agent --check --diff`

**Remediate**: same command without `--check`, after explicit user
approval.

**Propose a change to the role itself** (e.g. adding a new hypervisor to
`soe_vm_guest_agent_map`): never commit directly. On a branch named
`soe/vm_guest_agent/<short-desc>`, edit the role, validate locally
(`--syntax-check`, `ansible-lint roles/vm_guest_agent/`, `--check --diff`),
push, and open a PR titled `[vm_guest_agent] <what changed>` with the
`--check --diff` output in the body — then stop for human review. See
`docs/ARCHITECTURE.md`'s "Contribution workflow".

## Notes

- If `systemd-detect-virt` returns something not in `soe_vm_guest_agent_map`
  but the user says the host is a VM, ask rather than guessing which
  package to install — installing the wrong guest agent (e.g.
  `open-vm-tools` on a KVM guest) is wasted and can mask misconfiguration.
