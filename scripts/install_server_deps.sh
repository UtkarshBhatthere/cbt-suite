#!/bin/bash

# ==============================================================================
# Script Name: prep_ceph_node.sh
# Description: Installs CBT dependencies on a Ceph Node (OSD/MON/Client).
# Target OS:   Ubuntu 24.04
# ==============================================================================

set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

echo "[INFO] Updating repositories..."
add-apt-repository universe -y >/dev/null
apt-get update -y >/dev/null

echo "[INFO] Installing Monitoring & Control Tools (collectl, psmisc)..."
# collectl: Required by CBT to record system stats
# psmisc: Required for 'killall' to clean up processes
# sysstat: Useful for iostat/sar baseline checks
apt-get install -y collectl psmisc sysstat

echo "[INFO] Installing Profiling Tools (perf, blktrace)..."
# These allow you to turn on 'profilers' in the CBT YAML later
apt-get install -y \
  blktrace \
  linux-tools-common \
  linux-tools-generic \
  "linux-tools-$(uname -r)"

echo "[INFO] checking if this is a Client node..."
# If this node doesn't have OSDs, it's likely a client, so we install FIO.
# (Safe to install on OSD nodes too, just takes a bit of space)
apt-get install -y fio librbd-dev

echo "[INFO] Verifying SSH Server..."
# CBT requires SSH access. Ensure it is running.
systemctl enable --now ssh

echo "[INFO] Node Preparation Complete."
