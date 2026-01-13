#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <path_to_private_key> <path_to_host_list>"
  exit 1
fi

PRIV_KEY_PATH=$1
HOST_LIST=$2
REMOTE_USER="ubuntu"
DEST_KEY_NAME="id_ed25519" # Ensure this matches the key type you are sending

if [ ! -f "$PRIV_KEY_PATH" ]; then
  echo "Error: Private key file not found at $PRIV_KEY_PATH"
  exit 1
fi

if [ ! -f "$HOST_LIST" ]; then
  echo "Error: Host list file not found at $HOST_LIST"
  exit 1
fi

echo "--------------------------------------------------"
echo "Starting PRIVATE key distribution"
echo "--------------------------------------------------"

# We use a custom File Descriptor (3) to read the file.
# This ensures that commands inside the loop (like ssh) cannot accidentally
# consume the lines meant for the loop itself.
while IFS= read -r HOST <&3 || [ -n "$HOST" ]; do

  # Skip empty lines or lines starting with #
  if [[ -z "$HOST" ]] || [[ "$HOST" =~ ^# ]]; then
    continue
  fi

  echo "Processing host: $HOST ..."

  # Step A: Create .ssh folder
  # Added -n to prevent reading stdin, though the FD 3 method below handles this too.
  ssh -n -o StrictHostKeyChecking=no "$REMOTE_USER@$HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

  if [ $? -ne 0 ]; then
    echo "❌ Failed: Could not connect to $HOST"
    continue
  fi

  # Step B: Copy the file
  scp -o StrictHostKeyChecking=no "$PRIV_KEY_PATH" "$REMOTE_USER@$HOST:~/.ssh/$DEST_KEY_NAME"

  # Step C: Set strict permissions
  if [ $? -eq 0 ]; then
    # Added -n here as well
    ssh -n -o StrictHostKeyChecking=no "$REMOTE_USER@$HOST" "chmod 600 ~/.ssh/$DEST_KEY_NAME"
    echo "✅ Success: Private key installed on $HOST"
  else
    echo "❌ Failed: Could not scp key to $HOST"
  fi

  echo "--------------------------------------------------"

done 3<"$HOST_LIST"
# ^ The '3<' redirects the file to File Descriptor 3, completely isolating it from SSH.

echo "Distribution finished."
