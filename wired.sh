#!/bin/sh

PATH="/opt/local/bin:/usr/local/bin:/usr/bin:/bin"
CFLAGS="-gdwarf-2"

if echo $CONFIGURATION | grep -q Debug; then
	CFLAGS="$CFLAGS -O0"
else
	CFLAGS="$CFLAGS -O2"
fi

cd wired

BUILD=$(./config.guess)

for i in $ARCHS; do
	if [ ! -f "$PROJECT_TEMP_DIR/make/$i/Makefile" ]; then
		HOST="$i-apple-darwin$RELEASE"
		ARCH_CFLAGS="$CFLAGS"
		ARCH_CPPFLAGS="$CPPFLAGS"

		if [ "$i" = "i386" -o "$i" = "ppc" ]; then
			SDKROOT="$DEVELOPER_SDK_DIR/MacOSX10.4u.sdk"
			MACOSX_DEPLOYMENT_TARGET=10.4
		elif [ "$i" = "x86_64" -o "$i" = "ppc64" ]; then
			SDKROOT="$DEVELOPER_SDK_DIR/MacOSX10.5.sdk"
			MACOSX_DEPLOYMENT_TARGET=10.5
		fi

		ARCH_CPPFLAGS="$ARCH_CPPFLAGS -isysroot $SDKROOT -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

		SDKROOT=$(eval echo SDKROOT_$i); SDKROOT=$(eval echo \$$SDKROOT)
		MACOSX_DEPLOYMENT_TARGET=$(eval echo MACOSX_DEPLOYMENT_TARGET_$i); MACOSX_DEPLOYMENT_TARGET=$(eval echo \$$MACOSX_DEPLOYMENT_TARGET)
		RELEASE=$(uname -r)
		BUILD=$("$SRCROOT/wired/config.guess")
		
		CC="gcc -arch $i" CFLAGS="$ARCH_CFLAGS" CPPFLAGS="$ARCH_CPPFLAGS -I$PROJECT_TEMP_DIR/make/$i" ./configure --build="$BUILD" --host="$HOST" --enable-warnings --srcdir="$SRCROOT/wired" --with-objdir="$OBJECT_FILE_DIR/$i" --with-rundir="$PROJECT_TEMP_DIR/run/$i/wired" --prefix="$PROJECT_TEMP_DIR/Package/Contents/Library" --with-fake-prefix="/Library" --with-wireddir="Wired2.0" --mandir="$PROJECT_TEMP_DIR/Package/Contents/usr/local/man" --without-libwired || exit 1
		
		mkdir -p "$PROJECT_TEMP_DIR/make/$i/libwired" "$PROJECT_TEMP_DIR/run/$i" "$BUILT_PRODUCTS_DIR"
		mv config.h Makefile "$PROJECT_TEMP_DIR/make/$i/"
		cp -r run "$PROJECT_TEMP_DIR/run/$i/wired"

		cd libwired
		CC="gcc -arch $i" CFLAGS="$ARCH_CFLAGS" CPPFLAGS="$ARCH_CPPFLAGS -I$PROJECT_TEMP_DIR/make/$i/libwired" ./configure --build="$BUILD" --host="$HOST" --enable-warnings --enable-ssl --enable-pthreads --enable-libxml2 --enable-p7 --srcdir="$SRCROOT/wired/libwired" --with-objdir="$OBJECT_FILE_DIR/$i" --with-rundir="$PROJECT_TEMP_DIR/run/$i/wired/libwired" || exit 1
		mv config.h Makefile "$PROJECT_TEMP_DIR/make/$i/libwired"
		cp -r run "$PROJECT_TEMP_DIR/run/$i/wired/libwired"
		cd ..
	fi
	
	cd "$PROJECT_TEMP_DIR/make/$i"
	make -f "$PROJECT_TEMP_DIR/make/$i/Makefile" || exit 1
done
