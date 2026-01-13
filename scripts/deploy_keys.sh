#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <path_to_public_key> <path_to_host_list>"
  echo "Example: $0 ~/.ssh/id_rsa.pub ./servers.txt"
  exit 1
fi

KEY_PATH=$1
HOST_LIST=$2
REMOTE_USER="ubuntu"

# 1. Validate the Public Key exists
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: Public key file not found at $KEY_PATH"
  exit 1
fi

# 2. Validate the Host List file exists
if [ ! -f "$HOST_LIST" ]; then
  echo "Error: Host list file not found at $HOST_LIST"
  exit 1
fi

echo "--------------------------------------------------"
echo "Starting key deployment (skipping host confirmation)"
echo "Key: $KEY_PATH"
echo "Target User: $REMOTE_USER"
echo "--------------------------------------------------"

# 3. Loop through the host list
while IFS= read -r HOST || [ -n "$HOST" ]; do
  # Skip empty lines or lines starting with #
  if [[ -z "$HOST" ]] || [[ "$HOST" =~ ^# ]]; then
    continue
  fi

  echo "Processing host: $HOST ..."

  # 4. Run ssh-copy-id with StrictHostKeyChecking disabled
  # -o StrictHostKeyChecking=no: Automatically accepts new host keys
  # -o ConnectTimeout=5: Times out after 5 seconds if host is unreachable
  ssh-copy-id -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$REMOTE_USER@$HOST"

  if [ $? -eq 0 ]; then
    echo "✅ Success: Key copied to $HOST"
  else
    echo "❌ Failed: Could not copy key to $HOST"
  fi

  echo "--------------------------------------------------"

done <"$HOST_LIST"

echo "Deployment finished."
