#!/bin/bash

# Check if a comment (usually email) was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <comment_email> [optional_key_name]"
  echo "Example: $0 devops@example.com my_server_key"
  exit 1
fi

COMMENT=$1
KEY_NAME=${2:-id_ed25519} # Default name if not provided
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# 1. Check if key already exists to prevent accidental overwrite
if [ -f "$KEY_PATH" ]; then
  echo "❌ Error: A key named '$KEY_NAME' already exists in ~/.ssh/"
  echo "   Please choose a different name or delete the existing key."
  exit 1
fi

echo "--------------------------------------------------"
echo "Generating secure Ed25519 SSH key pair..."
echo "Comment: $COMMENT"
echo "Location: $KEY_PATH"
echo "--------------------------------------------------"

# 2. Generate the Key
# -t ed25519: Specifies the EdDSA algorithm (modern standard)
# -a 100:     Runs 100 rounds of KDF (Key Derivation Function).
#             Makes the passphrase harder to brute-force if the key file is stolen.
# -f:         Output filename
# -C:         Comment (useful for identifying keys in logs)
ssh-keygen -t ed25519 -a 100 -f "$KEY_PATH" -C "$COMMENT"

if [ $? -eq 0 ]; then
  echo "--------------------------------------------------"
  echo "✅ Success! Key pair generated."
  echo ""
  echo "Private Key: $KEY_PATH"
  echo "Public Key:  $KEY_PATH.pub"
  echo ""
  echo "Here is your public key:"
  cat "$KEY_PATH.pub"
else
  echo "❌ Error: Key generation failed."
  exit 1
fi
