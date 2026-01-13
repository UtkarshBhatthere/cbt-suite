#!/bin/bash

# --- Configuration ---
REMOTE_USER="ubuntu"
# ---------------------

# 1. Input Validation
if [ $# -lt 1 ]; then
    echo "Usage: $0 <nodes_list_file> [ppa:user/repo]"
    echo "Example (Distro Default): $0 hosts.txt"
    echo "Example (Custom PPA):     $0 hosts.txt ppa:myuser/ceph-custom"
    exit 1
fi

NODES_FILE="$1"
CUSTOM_PPA="$2"

# Check if nodes file exists
if [ ! -f "$NODES_FILE" ]; then
    echo "Error: File '$NODES_FILE' not found."
    exit 1
fi

echo "Reading nodes from: $NODES_FILE"

if [ -n "$CUSTOM_PPA" ]; then
    echo "Source: Custom PPA ($CUSTOM_PPA)"
else
    echo "Source: Default Distro Repositories"
fi
echo "--------------------------------------------------"

# 2. Iterate through the nodes file
grep -vE '^\s*($|#)' "$NODES_FILE" | while IFS= read -r NODE; do
    echo "Processing node: $NODE"

    # Construct the remote command based on whether a PPA is provided
    if [ -n "$CUSTOM_PPA" ]; then
        # Logic for Custom PPA:
        # 1. Update apt
        # 2. Install software-properties-common (needed for add-apt-repository)
        # 3. Add the PPA (using -y to accept prompts automatically)
        # 4. Update apt again to pull PPA metadata
        # 5. Install ceph-common
        REMOTE_CMD="export DEBIAN_FRONTEND=noninteractive; \
        sudo apt-get update -q && \
        sudo apt-get install -yq software-properties-common && \
        sudo add-apt-repository -y ${CUSTOM_PPA} && \
        sudo apt-get update -q && \
        sudo apt-get install -yq ceph-common"
    else
        # Logic for Default Distro Repo:
        # 1. Update apt
        # 2. Install ceph-common
        REMOTE_CMD="export DEBIAN_FRONTEND=noninteractive; \
        sudo apt-get update -q && \
        sudo apt-get install -yq ceph-common"
    fi

    # Execute via SSH
    # -n: Redirects stdin from /dev/null (prevents breaking the loop)
    # -o ConnectTimeout=5: Fail fast if node is down
    ssh -n -o ConnectTimeout=5 ${REMOTE_USER}@${NODE} "${REMOTE_CMD}"

    # Check exit status of the SSH command
    if [ $? -eq 0 ]; then
        echo "  -> [SUCCESS] ceph-common installed on $NODE"
    else
        echo "  -> [FAILED] Installation failed on $NODE"
    fi
    echo "--------------------------------------------------"
done

echo "Operation completed."