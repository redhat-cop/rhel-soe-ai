#!/usr/bin/env bash
# Brings time synchronization into compliance with the SOE baseline.
# Modifies the system. Only run with explicit user approval.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/soe_common.sh
source "$SCRIPT_DIR/lib/soe_common.sh"
soe_require_root

CHRONY_CONF="/etc/chrony.conf"
DEFAULT_POOL="2.rhel.pool.ntp.org iburst"

if ! rpm -q chrony >/dev/null 2>&1; then
  soe_info "Installing chrony"
  dnf install -y chrony
  soe_fixed "installed chrony package"
fi

if [ -f "$CHRONY_CONF" ] && ! grep -qE '^[[:space:]]*(server|pool)[[:space:]]+\S+' "$CHRONY_CONF"; then
  soe_info "No NTP server/pool found in $CHRONY_CONF; appending default pool"
  printf 'pool %s\n' "$DEFAULT_POOL" >>"$CHRONY_CONF"
  soe_fixed "added default pool '$DEFAULT_POOL' to $CHRONY_CONF"
fi

systemctl enable --now chronyd >/dev/null
soe_fixed "enabled and started chronyd"

echo
echo "Re-running audit to confirm end state:"
"$SCRIPT_DIR/audit.sh"
