#!/usr/bin/env bash
# Shared helpers for SOE domain skill audit/remediate scripts.
# Source this from a domain's scripts/audit.sh or scripts/remediate.sh.

SOE_PASS=0
SOE_FAIL=0

soe_pass() { printf '[PASS] %s\n' "$*"; SOE_PASS=$((SOE_PASS + 1)); }
soe_fail() { printf '[FAIL] %s\n' "$*"; SOE_FAIL=$((SOE_FAIL + 1)); }
soe_info() { printf '[INFO] %s\n' "$*"; }
soe_fixed() { printf '[FIXED] %s\n' "$*"; }

# Print a summary line and return non-zero if any check failed.
# Usage: soe_summary "<domain> audit"
soe_summary() {
  printf '\n--- %s: %d pass, %d fail ---\n' "${1:-summary}" "$SOE_PASS" "$SOE_FAIL"
  [ "$SOE_FAIL" -eq 0 ]
}

soe_is_rhel_family() {
  [ -f /etc/redhat-release ] && return 0
  grep -qiE '^ID(_LIKE)?=.*(rhel|fedora|centos)' /etc/os-release 2>/dev/null
}

soe_require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This action requires root privileges." >&2
    exit 1
  fi
}
