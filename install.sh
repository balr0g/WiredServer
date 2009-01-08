#!/bin/sh

SOURCE="$1"

install -m 775 -d "/Library/Wired2.0" || exit 1
install -m 755 -d "/Library/Wired2.0/etc" || exit 1
install -m 755 -d "/Library/Wired2.0/files" || exit 1

if [ ! -f "/Library/Wired2.0/banlist" ]; then
	install -m 644 "$SOURCE/Wired2.0/banlist" "/Library/Wired2.0" || exit 1
fi

if [ ! -f "/Library/Wired2.0/etc/wired.conf" ]; then
	install -m 644 "$SOURCE/Wired2.0/etc/wired.conf" "/Library/Wired2.0/etc" || exit 1
fi

export GROUP=$(id -gn)

perl -i -pe 's,port = 2000,port = 4871,' "/Library/Wired2.0/etc/wired.conf" || exit 1
perl -i -pe 's,files = files,files = $ENV{"HOME"}/Public,' "/Library/Wired2.0/etc/wired.conf" || exit 1
perl -i -pe 's,user = .+?,user = $ENV{"USER"},' "/Library/Wired2.0/etc/wired.conf" || exit 1
perl -i -pe 's,group = .+?,group = $ENV{"GROUP"},' "/Library/Wired2.0/etc/wired.conf" || exit 1

if [ ! -f "/Library/Wired2.0/groups" ]; then
	install -m 644 "$SOURCE/Wired2.0/groups" "/Library/Wired2.0" || exit 1
fi

if [ ! -f "/Library/Wired2.0/news" ]; then
	install -m 644 "$SOURCE/Wired2.0/news" "/Library/Wired2.0" || exit 1
fi

if [ ! -f "/Library/Wired2.0/users" ]; then
	install -m 644 "$SOURCE/Wired2.0/users" "/Library/Wired2.0" || exit 1
fi

install -m 755 "$SOURCE/Wired2.0/wired" "/Library/Wired2.0" || exit 1
install -m 644 "$SOURCE/Wired2.0/wired.xml" "/Library/Wired2.0" || exit 1
install -m 755 "$SOURCE/Wired2.0/wiredctl" "/Library/Wired2.0" || exit 1

touch "/Library/Wired2.0/wired.log"

echo "-L /Library/Wired2.0/wired.log -i 1000" > "/Library/Wired2.0/etc/wired.flags"

install -m 755 -d "$HOME/Library/LaunchDaemons" || exit 1
install -m 644 "$SOURCE/com.zankasoftware.WiredServer.plist" "$HOME/Library/LaunchDaemons" || exit 1

exit 0
