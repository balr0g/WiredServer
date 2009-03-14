#!/bin/sh

SOURCE="$1"
LIBRARY="$2"
MIGRATE="$3"

install -m 775 -d "$LIBRARY/Wired" || exit 1

if [ ! -f "$LIBRARY/Wired/banlist" ]; then
	install -m 644 "$SOURCE/Wired/banlist" "$LIBRARY/Wired" || exit 1
fi

if [ ! -f "$LIBRARY/Wired/banner.png" ]; then
	install -m 644 "$SOURCE/Wired/banner.png" "$LIBRARY/Wired" || exit 1
fi

if [ ! -d "$LIBRARY/Wired/board/" ]; then
	install -m 755 -d "$LIBRARY/Wired/board" || exit 1
	install -m 755 -d "$LIBRARY/Wired/board/General" || exit 1
	install -m 755 -d "$LIBRARY/Wired/board/General/.wired" || exit 1
	install -m 644 "$SOURCE/Wired/board/General/.wired/permissions" "$LIBRARY/Wired/board/General/.wired/" || exit 1
	install -m 755 -d "$LIBRARY/Wired/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/" || exit 1
	install -m 644 "$SOURCE/Wired/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/AD70D7CB-F789-4030-A92F-40D546DBE1D9.WiredPost" "$LIBRARY/Wired/board/General/BC5B30BF-AC4F-4FEE-BB92-C5F3A5436E18.WiredThread/" || exit 1
fi

if [ ! -d "$LIBRARY/Wired/etc/" ]; then
	install -m 755 -d "$LIBRARY/Wired/etc/" || exit 1
	install -m 644 "$SOURCE/Wired/etc/wired.conf" "$LIBRARY/Wired/etc" || exit 1
fi

install -m 755 -d "$LIBRARY/Wired/files/" || exit 1

if [ ! -f "$LIBRARY/Wired/groups" ]; then
	install -m 644 "$SOURCE/Wired/groups" "$LIBRARY/Wired" || exit 1
fi

if [ ! -f "$LIBRARY/Wired/users" ]; then
	install -m 644 "$SOURCE/Wired/users" "$LIBRARY/Wired" || exit 1
fi

install -m 755 "$SOURCE/Wired/wired" "$LIBRARY/Wired" || exit 1
install -m 644 "$SOURCE/Wired/wired.xml" "$LIBRARY/Wired" || exit 1
install -m 755 "$SOURCE/Wired/wiredctl" "$LIBRARY/Wired" || exit 1

echo "-L $LIBRARY/Wired/wired.log -i 1000" > "$LIBRARY/Wired/etc/wired.flags"
touch "$LIBRARY/Wired/wired.log"

install -m 755 -d "$LIBRARY/LaunchDaemons" || exit 1

cat <<EOF >"$LIBRARY/LaunchDaemons/com.zankasoftware.WiredServer.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<true/>
	<key>Label</key>
	<string>com.zankasoftware.WiredServer</string>
	<key>OnDemand</key>
	<false/>
	<key>ProgramArguments</key>
	<array>
		<string>$LIBRARY/Wired/wired</string>
		<string>-x</string>
		<string>-d</string>
		<string>$LIBRARY/Wired</string>
		<string>-l</string>
		<string>-L</string>
		<string>$LIBRARY/Wired/wired.log</string>
		<string>-i</string>
		<string>1000</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>WorkingDirectory</key>
	<string>$LIBRARY/Wired</string>
</dict>
</plist>
EOF

chmod 644 "$LIBRARY/LaunchDaemons/com.zankasoftware.WiredServer.plist"

if [ "$MIGRATE" = "YES" -a "$LIBRARY" != "/Library" ]; then
	cp "/Library/Wired/banlist" "$LIBRARY/Wired/banlist"
	cp "/Library/Wired/banner.png" "$LIBRARY/Wired/banner.png"
	cp "/Library/Wired/etc/wired.conf" "$LIBRARY/Wired/etc/wired.conf"
	cp "/Library/Wired/groups" "$LIBRARY/Wired/groups"
	cp "/Library/Wired/news" "$LIBRARY/Wired/news"
	cp "/Library/Wired/users" "$LIBRARY/Wired/users"
fi

export GROUP=$(id -gn)
export LIBRARY

perl -i -pe 's,^#?port = 2000$,port = 4871,' "$LIBRARY/Wired/etc/wired.conf" || exit 1
perl -i -pe 's,^#?files = files$,files = $ENV{"HOME"}/Public,' "$LIBRARY/Wired/etc/wired.conf" || exit 1
perl -i -pe 's,^#?user = .+$,user = $ENV{"USER"},' "$LIBRARY/Wired/etc/wired.conf" || exit 1
perl -i -pe 's,^#?group = .+$,group = $ENV{"GROUP"},' "$LIBRARY/Wired/etc/wired.conf" || exit 1
perl -i -pe 's,^#?index time = .+$,index time = 3600,' "$LIBRARY/Wired/etc/wired.conf" || exit 1

perl -i -pe 's,/Library/Wired,$ENV{"LIBRARY"}/Wired,' "$LIBRARY/Wired/wiredctl" || exit 1

exit 0
