#!/bin/bash
# Command-chain hook to support CBT_PREFER_HOST_TOOLS environment variable.
# When CBT_PREFER_HOST_TOOLS=1, reorders PATH to prefer host binaries over snap binaries.

if [ "$CBT_PREFER_HOST_TOOLS" = "1" ]; then
    # Extract original system PATH (excluding snap paths)
    SYSTEM_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^$SNAP" | tr '\n' ':' | sed 's/:$//')
    
    # Reorder: system paths first, then snap paths
    export PATH="$SYSTEM_PATH:$SNAP/usr/sbin:$SNAP/usr/bin:$SNAP/bin"
fi

# Execute the actual command
exec "$@"
