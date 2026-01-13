#!/bin/bash

REMOTE_USER="ubuntu"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <remote_mon_host>"
    exit 1
fi

REMOTE_HOST="$1"

echo "=== Restoring Ceph Defaults on $REMOTE_HOST ==="

ssh -T ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
    echo "remote: Unsetting OSD flags..."
    FLAGS="noscrub nodeep-scrub nobackfill norecover norebalance noout nodown"
    for FLAG in $FLAGS; do
        sudo ceph osd unset $FLAG > /dev/null 2>&1
        echo "  -> Flag unset: $FLAG"
    done

    echo "remote: Re-enabling Autoscaler..."
    POOLS=$(sudo ceph osd pool ls)
    for POOL in $POOLS; do
        # Usually 'on' or 'warn' is the default. Setting to 'on'.
        sudo ceph osd pool set "$POOL" pg_autoscale_mode on > /dev/null 2>&1
        echo "  -> Autoscaler ON for pool: $POOL"
    done
    
    sudo ceph config set global osd_pool_default_pg_autoscale_mode on
    
    echo "remote: Final Status:"
    sudo ceph -s
EOF