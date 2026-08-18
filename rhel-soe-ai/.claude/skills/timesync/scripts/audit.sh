#!/usr/bin/env bash
# Read-only audit of time synchronization against the SOE baseline.
# Never modifies the system. Exit 0 if compliant, 1 if any check fails.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/soe_common.sh
source "$SCRIPT_DIR/lib/soe_common.sh"

CHRONY_CONF="/etc/chrony.conf"

soe_is_rhel_family || soe_info "Non-RHEL-family system detected; this skill targets RHEL-family systems (chronyd) and results may not apply."

if rpm -q chrony >/dev/null 2>&1; then
  soe_pass "chrony package is installed"
else
  soe_fail "chrony package is not installed"
fi

if systemctl is-enabled chronyd >/dev/null 2>&1; then
  soe_pass "chronyd service is enabled"
else
  soe_fail "chronyd service is not enabled"
fi

if systemctl is-active chronyd >/dev/null 2>&1; then
  soe_pass "chronyd service is active"
else
  soe_fail "chronyd service is not active"
fi

if [ -f "$CHRONY_CONF" ] && grep -qE '^[[:space:]]*(server|pool)[[:space:]]+\S+' "$CHRONY_CONF"; then
  soe_pass "at least one NTP server/pool is configured in $CHRONY_CONF"
else
  soe_fail "no NTP server/pool configured in $CHRONY_CONF"
fi

if command -v timedatectl >/dev/null 2>&1; then
  if [ "$(timedatectl show --property=NTPSynchronized --value 2>/dev/null)" = "yes" ]; then
    soe_pass "system clock is synchronized (timedatectl)"
  else
    soe_fail "system clock is not synchronized (timedatectl)"
  fi
else
  soe_info "timedatectl not available; skipping synchronization check"
fi

soe_summary "timesync audit"
