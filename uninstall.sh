#!/bin/sh

rm -rf /Library/Wired2.0 || exit 1

launchctl unload -w "$HOME/Library/LaunchDaemons/com.zankasoftware.WiredServer.plist" || exit 1
rm -f "$HOME/Library/LaunchDaemons/com.zankasoftware.WiredServer.plist" || exit 1

exit 0
