#!/usr/bin/env bash
. ./toolchain-exports.sh

CURRDIR=$PWD
cd "`dirname $0`/../wolfssl"
alias modpath='PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib'

for toolc in $ARMMUSL $X86MUSL $MIPSMUSL $MIPSEB
do
	_host=$(find $toolc/bin -name "*rorschack*gcc" | sed 's/.*\///;s/-gcc//')

	modpath CC=$_host'-cc' CFLAGS="-Os -static -fomit-frame-pointer -falign-functions=1 \
	-falign-labels=1 -falign-loops=1 -falign-jumps=1 -ffunction-sections -fdata-sections" \
	./configure --host=$_host --enable-static --enable-singlethreaded --enable-openssh --disable-shared  \
	C_EXTRA_FLAGS="-DWOLFSSL_STATIC_RSA" || exit $?

	modpath make clean
	modpath make

	cd ssl_helper-wolfssl

	modpath $_host'-gcc' -Os -Wall -I.. -c ssl_helper.c -o ssl_helper.o
	modpath $_host'-gcc' -static -Wl,--start-group ssl_helper.o -lm ../src/.libs/libwolfssl.a -Wl,--end-group -o ssl_helper
	modpath $_host'-strip' ssl_helper
	[[ $_host =~ 86 ]] && _host=x86
	[[ $_host == mips ]] && _host=mipseb
    case $_host in
        *86) _host=x86
            ;;
        mips) _host=mipseb
            ;;
        mipsel) _host=mips
            ;;
    esac
	mv ssl_helper ../../out/ssl_helper-"$(cut -d- -f1 <<<$_host)"
	cd ..
done

cd $CURRDIR
