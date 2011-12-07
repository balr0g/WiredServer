#!/bin/sh

LIBRARY="$1"
WIREDDIR="Wired2"
rm -rf "$LIBRARY/$WIREDDIR" || exit 1

launchctl unload -w "$LIBRARY/LaunchAgents/com.zankasoftware.WiredServer2.plist" || exit 1
rm -f "$LIBRARY/LaunchAgents/com.zankasoftware.WiredServer2.plist" || exit 1

exit 0
