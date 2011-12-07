#!/bin/sh

SOURCE="$1"
LIBRARY="$2"
MIGRATE="$3"

WIREDDIR="Wired2"
install -m 775 -d "$LIBRARY/$WIREDDIR" || exit 1
install -m 755 -d "$LIBRARY/$WIREDDIR/etc/" || exit 1

if [ ! -f "$LIBRARY/$WIREDDIR/banlist" ]; then
	install -m 644 "$SOURCE/Wired/banlist" "$LIBRARY/$WIREDDIR" || exit 1
fi

install -m 644 "$SOURCE/Wired/banlist" "$LIBRARY/$WIREDDIR/banlist.dist" || exit 1

if [ ! -f "$LIBRARY/$WIREDDIR/banner.png" ]; then
	install -m 644 "$SOURCE/Wired/banner.png" "$LIBRARY/$WIREDDIR" || exit 1
fi

if [ ! -d "$LIBRARY/$WIREDDIR/board/" ]; then
	install -m 755 -d "$LIBRARY/$WIREDDIR/board" || exit 1
	install -m 755 -d "$LIBRARY/$WIREDDIR/board/General" || exit 1
	install -m 755 -d "$LIBRARY/$WIREDDIR/board/General/.wired" || exit 1
	install -m 644 "$SOURCE/Wired/board/General/.wired/permissions" "$LIBRARY/$WIREDDIR/board/General/.wired/" || exit 1
	install -m 755 -d "$LIBRARY/$WIREDDIR/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/" || exit 1
	install -m 644 "$SOURCE/Wired/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/AD70D7CB-F789-4030-A92F-40D546DBE1D9.WiredPost" "$LIBRARY/$WIREDDIR/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/" || exit 1
fi

if [ ! -f "$LIBRARY/$WIREDDIR/etc/wired.conf" ]; then
	install -m 644 "$SOURCE/Wired/etc/wired.conf" "$LIBRARY/$WIREDDIR/etc" || exit 1
fi

install -m 644 "$SOURCE/Wired/etc/wired.conf" "$LIBRARY/$WIREDDIR/etc/wired.conf.dist" || exit 1

if [ -f "$LIBRARY/$WIREDDIR/events" ]; then
	rm -f "$LIBRARY/$WIREDDIR/events"
fi

install -m 755 -d "$LIBRARY/$WIREDDIR/events/" || exit 1

if [ ! -f "$LIBRARY/$WIREDDIR/events/current" ]; then \
	install -m 644 "$SOURCE/Wired/events/current" "$LIBRARY/$WIREDDIR/events/" || exit 1
fi

install -m 755 -d "$LIBRARY/$WIREDDIR/files/" || exit 1

if [ ! -f "$LIBRARY/$WIREDDIR/groups" ]; then
	install -m 644 "$SOURCE/Wired/groups" "$LIBRARY/$WIREDDIR" || exit 1
fi

install -m 644 "$SOURCE/Wired/groups" "$LIBRARY/$WIREDDIR/groups.dist" || exit 1

if [ ! -f "$LIBRARY/$WIREDDIR/users" ]; then
	install -m 644 "$SOURCE/Wired/users" "$LIBRARY/$WIREDDIR" || exit 1
fi

install -m 644 "$SOURCE/Wired/users" "$LIBRARY/$WIREDDIR/users.dist" || exit 1

install -m 755 "$SOURCE/Wired/wired" "$LIBRARY/$WIREDDIR" || exit 1
install -m 644 "$SOURCE/Wired/wired.xml" "$LIBRARY/$WIREDDIR" || exit 1
install -m 755 "$SOURCE/Wired/wiredctl" "$LIBRARY/$WIREDDIR" || exit 1

echo "-L $LIBRARY/$WIREDDIR/wired.log -i 1000" > "$LIBRARY/$WIREDDIR/etc/wired.flags"
touch "$LIBRARY/$WIREDDIR/wired.log"

install -m 700 -d "$HOME/Library/LaunchAgents" || exit 1

if [ $(defaults read "$HOME/Library/LaunchAgents/com.zankasoftware.WiredServer" Disabled 2>/dev/null || echo 1) = "1" ]; then
	DISABLED="true"
else
	DISABLED="false"
fi

cat <<EOF >"$HOME/Library/LaunchAgents/com.zankasoftware.WiredServer2.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<$DISABLED/>
	<key>Label</key>
	<string>com.zankasoftware.WiredServer</string>
	<key>KeepAlive</key>
	<true/>
	<key>OnDemand</key>
	<false/>
	<key>ProgramArguments</key>
	<array>
		<string>$LIBRARY/$WIREDDIR/wired</string>
		<string>-x</string>
		<string>-d</string>
		<string>$LIBRARY/$WIREDDIR</string>
		<string>-l</string>
		<string>-L</string>
		<string>$LIBRARY/$WIREDDIR/wired.log</string>
		<string>-i</string>
		<string>1000</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>WorkingDirectory</key>
	<string>$LIBRARY/$WIREDDIR</string>
</dict>
</plist>
EOF

chmod 644 "$HOME/Library/LaunchAgents/com.zankasoftware.WiredServer2.plist"

if [ "$MIGRATE" = "YES" -a "$LIBRARY" != "/Library" ]; then
	cp "/Library/Wired/banlist" "$LIBRARY/$WIREDDIR/banlist"
	cp "/Library/Wired/banner.png" "$LIBRARY/$WIREDDIR/banner.png"
	cp "/Library/Wired/etc/wired.conf" "$LIBRARY/$WIREDDIR/etc/wired.conf"
	cp "/Library/Wired/groups" "$LIBRARY/$WIREDDIR/groups"
	cp "/Library/Wired/news" "$LIBRARY/$WIREDDIR/news"
	cp "/Library/Wired/users" "$LIBRARY/$WIREDDIR/users"
	
	perl -i -pe 's,^ban time =,#ban time =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^bandwidth =,#bandwidth =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^banlist =,#banlist =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^certificate =,#certificate =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^client downloads =,#client downloads =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^client uploads =,#client uploads =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^control cipher =,#control cipher =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^groups =,#groups =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^idle time =,#idle time =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^index =,#index =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^index time =,#index time =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^news =,#news =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^pid =,#pid =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^search method =,#search method =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^show dot files =,#show dot files =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^show invisible files =,#show invisible files =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^status =,#status =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^transfer cipher =,#transfer cipher =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^users =,#users =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
	perl -i -pe 's,^zeroconf =,#zeroconf =,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
fi

export GROUP=$(id -gn)
export LIBRARY

perl -i -pe 's,^#?banner = .+$,banner = $ENV{"LIBRARY"}/$ENV{"$WIREDDIR"}/banner.png,' "$LIBRARY/$ENV{"$WIREDDIR"}/etc/wired.conf" || exit 1
perl -i -pe 's,^#?port = 2000$,port = 4871,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
perl -i -pe 's,^#?files = files$,files = $ENV{"HOME"}/Public,' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
perl -i -pe 's,^#?user = .+$,user = $ENV{"USER"},' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1
perl -i -pe 's,^#?group = .+$,group = $ENV{"GROUP"},' "$LIBRARY/$WIREDDIR/etc/wired.conf" || exit 1

perl -i -pe 's,/Library/Wired,$ENV{"LIBRARY"}/Wired,' "$LIBRARY/$WIREDDIR/wiredctl" || exit 1

exit 0
