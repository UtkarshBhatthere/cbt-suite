#!/bin/bash

# ==============================================================================
# Script Name: install_hyperconverged_deps.sh
# Target OS:   Ubuntu 24.04 LTS (Noble Numbat)
# Description: Installs Ceph Benchmarking Tool (CBT) dependencies for a
#              hyperconverged environment (combines client + server packages).
# ==============================================================================

set -e

# --- Helper Functions ---

log_info() {
  echo -e "\e[32m[INFO] $1\e[0m"
}

log_err() {
  echo -e "\e[31m[ERROR] $1\e[0m"
}

# --- Pre-flight Checks ---

if [[ $EUID -ne 0 ]]; then
  log_err "This script must be run as root (sudo)."
  exit 1
fi

# Ensure we are actually on Ubuntu 24.04 to prevent package mismatches
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" != "ubuntu" ]]; then
    log_err "This script is strictly for Ubuntu. Detected: $ID"
    exit 1
  fi
else
  log_err "Cannot detect OS version."
  exit 1
fi

# --- Repository Setup ---

log_info "Enabling 'universe' repository (required for collectl, pdsh, seaborn)..."
add-apt-repository universe -y
apt-get update -y

# --- Package Installation ---

log_info "Installing System Tools..."
# pdsh: Parallel shell (orchestration)
# collectl: System metrics collector (monitoring)
# psmisc: Contains 'killall' (process management)
# sysstat: Useful for iostat/sar baseline checks
# git/wget: Retrieval tools
apt-get install -y \
  git \
  wget \
  pdsh \
  collectl \
  psmisc \
  sysstat \
  ssh

log_info "Installing Python 3 Dependencies (via APT)..."
# strictly using python3-* debian packages instead of pip
apt-get install -y \
  python3-all \
  python3-pip \
  python3-yaml \
  python3-lxml \
  python3-pandas \
  python3-matplotlib \
  python3-seaborn \
  python3-numpy

log_info "Installing Kernel Profiling Tools (perf, blktrace)..."
# 'perf' and 'blktrace' are required for deep profiling options in CBT
apt-get install -y \
  blktrace \
  linux-tools-common \
  linux-tools-generic \
  "linux-tools-$(uname -r)"

log_info "Installing Ceph Client Tools..."
# fio: Flexible I/O tester (required for benchmarking)
# librbd-dev: Ceph RADOS Block Device library
apt-get install -y fio librbd-dev

# --- Configuration Tweaks ---

log_info "Configuring pdsh to use SSH by default..."
# By default, debian pdsh might try to use rsh or fail if not configured.
# We enforce SSH via an environment profile script.
echo "export PDSH_RCMD_TYPE=ssh" >/etc/profile.d/pdsh_ssh_default.sh
chmod +x /etc/profile.d/pdsh_ssh_default.sh

# Apply it to the current session context if the user keeps using this shell
export PDSH_RCMD_TYPE=ssh

log_info "Verifying SSH Server..."
# CBT requires SSH access. Ensure it is running.
systemctl enable --now ssh

# --- Verification ---

log_info "Verifying installations..."

if python3 -c "import seaborn; import pandas; import yaml; print('Python deps loaded successfully')" 2>/dev/null; then
  log_info "Python dependencies verified."
else
  log_err "Python dependency check failed."
  exit 1
fi

if pdsh -V 2>&1 | grep -q "rcmd modules:.*ssh"; then
  log_info "pdsh installed with SSH module."
else
  log_err "pdsh seems to lack SSH support."
  exit 1
fi

if command -v fio >/dev/null 2>&1; then
  log_info "fio (I/O benchmarking tool) verified."
else
  log_err "fio installation check failed."
  exit 1
fi

log_info "========================================"
log_info "Hyperconverged Setup Complete for Ubuntu 24.04!"
log_info "All CBT dependencies installed (client + server packages)."
log_info "You can now clone CBT: git clone https://github.com/ceph/cbt.git"
log_info "Note: You may need to log out and log back in for 'pdsh' env vars to apply globally."
log_info "========================================"
