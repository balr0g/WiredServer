#!/bin/sh

LIBRARY="$1"

rm -rf "$LIBRARY/Wired" || exit 1

launchctl unload -w "$LIBRARY/LaunchDaemons/com.zankasoftware.WiredServer.plist" || exit 1
rm -f "$LIBRARY/LaunchDaemons/com.zankasoftware.WiredServer.plist" || exit 1

exit 0
