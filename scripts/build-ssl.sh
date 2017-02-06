#!/usr/bin/env bash
. ./toolchain-exports.sh

CURRDIR=$PWD
cd "`dirname $0`/../wolfssl"
for toolc in $ARMMUSL $X86MUSL $MIPSMUSL $MIPSEB
do
	_host=$(find $toolc/bin -name "*rorschack*gcc" | sed 's/.*\///;s/-gcc//')

	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib CC=$_host'-cc' CFLAGS="-Os -static -fomit-frame-pointer -falign-functions=1 \
	-falign-labels=1 -falign-loops=1 -falign-jumps=1 -ffunction-sections -fdata-sections" \
	./configure --host=$_host --enable-static --enable-singlethreaded --enable-openssh --disable-shared  \
	C_EXTRA_FLAGS="-DWOLFSSL_STATIC_RSA" > /dev/null || exit $?

	echo "Building $(cut -d- -f1 <<< $_host) ssl_helper--"
	make clean
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib make -j$CORES &>/dev/null

	cd ssl_helper-wolfssl

	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-gcc' -Os -Wall -I.. -c ssl_helper.c -o ssl_helper.o
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-gcc' -static -Wl,--start-group ssl_helper.o -lm ../src/.libs/libwolfssl.a -Wl,--end-group -o ssl_helper
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-strip' ssl_helper
	[[ $_host =~ 86 ]] && _host=x86
	[[ $_host == mips ]] && _host=mipseb
	case $_host in
	*86)
		_host=x86
		;;
	mips)
		_host=mipseb
		;;
	mipsel)
		_host=mips
		;;
	esac
mv -v ssl_helper ../../out/ssl_helper-"$(cut -d- -f1 <<<$_host)" || exit 1
cd ..
done

cd $CURRDIR
