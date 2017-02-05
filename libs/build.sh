#!/usr/bin/env zsh

set -e

interactive=$1

[[ -z $toolc ]] && exit 1

alias modpath='PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib'

_host=$(find $toolc/bin -name "*rorschack*gcc" | sed 's/.*\///;s/-gcc//')
_sysroot=$(find $toolc -type d -name sysroot)
mkdir -p $_sysroot/lib/pkgconfig

echo $toolc
enter='read enter'
for arg in $*
do
	if [[ $arg == --noprompt || $arg == -np ]]
	then enter='echo noprompt'
	fi
done

cd pcre*  ##PCRE

modpath ./configure --host=arm-linux \
--with-sysroot=$_sysroot --disable-shared --enable-static \
--enable-unicode-properties CC=$_host'-cc' CXX=$_host'-g++' CFLAGS='-Os -Wno-error -fPIC' CXXFLAGS='-Os'
modpath make clean
modpath make

cp -av $interactive .libs/libpcre*.{a,la} $_sysroot/lib
ls pcre*.h | grep -v _internal | xargs -I{} cp -av $interactive {} $_sysroot/usr/include
cp -av $interactive libpcre*.pc $_sysroot/lib/pkgconfig

echo "Press enter to continue..."
eval $enter

cd ../libsepol* ##SEPOL

modpath make clean
modpath make CC=$_host'-cc' CXX=$_host'-g++' CFLAGS='-Os -Wno-error' DESTDIR=$_sysroot

cp -arv $interactive include/sepol $_sysroot/usr/include
cp -av $interactive src/libsepol*.{a,so*} $_sysroot/lib
cp -av $interactive src/libsepol*.pc $_sysroot/lib/pkgconfig

echo "Press enter to continue..."
eval $enter

cd ../libselinux* ##SELINUX

modpath make clean
modpath make CC=$_host'-cc' CXX=$_host'-g++' CFLAGS='-Os -Wno-error' DESTDIR=$_sysroot

cp -arv $interactive include/selinux $_sysroot/usr/include
cp -av $interactive src/libselinux*.{a,so*} $_sysroot/lib
cp -av $interactive src/libselinux*.pc $_sysroot/lib/pkgconfig
