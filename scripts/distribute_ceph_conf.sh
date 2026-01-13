#!/bin/bash

# --- Configuration ---
REMOTE_USER="ubuntu"
DEST_DIR="/etc/ceph/"
# ---------------------

# 1. Input Validation
if [ $# -lt 2 ]; then
    echo "Usage: $0 <nodes_list_file> <file_to_copy> [file_to_copy ...]"
    echo "Example: $0 hosts.txt ceph.conf ceph.client.admin.keyring"
    exit 1
fi

NODES_FILE="$1"

# Check if the nodes file exists
if [ ! -f "$NODES_FILE" ]; then
    echo "Error: File '$NODES_FILE' not found."
    exit 1
fi

# Shift arguments so $@ now only contains the files to copy
shift
FILES_TO_COPY="$@"

echo "Reading nodes from: $NODES_FILE"
echo "Files to distribute: $FILES_TO_COPY"
echo "Target Permissions: 644"
echo "--------------------------------------------------"

# 2. Iterate through the nodes file
grep -vE '^\s*($|#)' "$NODES_FILE" | while IFS= read -r NODE; do
    echo "Processing node: $NODE"

    # Step A: SCP files to /tmp/
    scp -q -o ConnectTimeout=5 $FILES_TO_COPY ${REMOTE_USER}@${NODE}:/tmp/

    if [ $? -eq 0 ]; then
        # Step B: Move files to destination and set permissions to 644
        echo "  -> Files staged in /tmp. Moving to $DEST_DIR and setting mode 644..."
        
        for FILE in $FILES_TO_COPY; do
            BASENAME=$(basename "$FILE")
            
            # SSH command:
            # 1. sudo mv: Move file from /tmp to /etc/ceph/
            # 2. sudo chmod 644: Set permissions to read/write for owner, read-only for others
            ssh -n ${REMOTE_USER}@${NODE} "sudo mv /tmp/${BASENAME} ${DEST_DIR} && sudo chmod 644 ${DEST_DIR}${BASENAME}"
        done

        echo "  -> [SUCCESS] $NODE"
    else
        echo "  -> [FAILED] Could not connect or copy to $NODE"
    fi
    echo "--------------------------------------------------"
done

echo "Operation completed."