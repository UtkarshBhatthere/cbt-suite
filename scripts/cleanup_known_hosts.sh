#!/bin/bash

# ==============================================================================
# Script Name: clean_known_hosts.sh
# Description: Removes entries for a list of hosts from ~/.ssh/known_hosts
# Usage:       ./clean_known_hosts.sh <hosts_list_file>
# ==============================================================================

HOST_LIST=$1
KNOWN_HOSTS=~/.ssh/known_hosts

# --- Validation ---

if [[ -z "$HOST_LIST" ]]; then
  echo "Usage: $0 <hosts_file>"
  exit 1
fi

if [[ ! -f "$HOST_LIST" ]]; then
  echo "[ERROR] File '$HOST_LIST' not found."
  exit 1
fi

# --- Main Loop ---

echo "[INFO] Cleaning entries from $KNOWN_HOSTS..."

while IFS= read -r HOST || [ -n "$HOST" ]; do
  # Skip empty lines or comments
  [[ -z "$HOST" || "$HOST" =~ ^# ]] && continue

  # ssh-keygen -R is the standard way to remove hosts
  # -f specifies the known_hosts file location
  # > /dev/null suppresses the standard "Host key verification failed..." output
  ssh-keygen -f "$KNOWN_HOSTS" -R "$HOST" >/dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    echo "Removed: $HOST"
  else
    echo "Skipped (Not found/Error): $HOST"
  fi

done <"$HOST_LIST"

echo "[INFO] Done. A backup was created at ${KNOWN_HOSTS}.old"
