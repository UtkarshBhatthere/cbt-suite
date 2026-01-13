#!/bin/bash

# --- Configuration ---
REMOTE_USER="ubuntu"
# ---------------------

# 1. Input Validation
if [ $# -lt 1 ]; then
    echo "Usage: $0 <remote_mon_host>"
    echo "Example: $0 192.168.1.10"
    exit 1
fi

REMOTE_HOST="$1"

echo "=== Connecting to $REMOTE_HOST to prepare Ceph for benchmarking ==="
echo "Target: $REMOTE_USER@$REMOTE_HOST"
echo "--------------------------------------------------"

# 2. Execute commands remotely via SSH
# We use 'EOF' (quoted) to prevent local variable expansion. 
# Everything between << 'EOF' and EOF is executed on the remote server.

ssh -T ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'

    # Function to print status
    log() { echo "  -> $1"; }

    # Check for sudo/root
    if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        echo "Error: Remote user needs passwordless sudo."
        exit 1
    fi

    echo "remote: Disabling background OSD operations..."
    
    # 1. Set OSD Flags
    FLAGS="noscrub nodeep-scrub nobackfill norecover norebalance noout nodown"
    for FLAG in $FLAGS; do
        sudo ceph osd set $FLAG > /dev/null 2>&1
        log "Flag set: $FLAG"
    done

    # 2. Disable Autoscaler on existing pools
    echo "remote: Disabling PG Autoscaler..."
    
    # Get list of pools
    POOLS=$(sudo ceph osd pool ls)
    
    if [ -n "$POOLS" ]; then
        for POOL in $POOLS; do
            sudo ceph osd pool set "$POOL" pg_autoscale_mode off > /dev/null 2>&1
            log "Autoscaler OFF for pool: $POOL"
        done
    else
        log "No pools found."
    fi

    # 3. Disable Autoscaler globally for future pools
    sudo ceph config set global osd_pool_default_pg_autoscale_mode off
    log "Global default autoscaler set to OFF"

    echo "--------------------------------------------------"
    echo "remote: Current Cluster Status:"
    sudo ceph -s
EOF

echo "--------------------------------------------------"
echo "Operation completed."