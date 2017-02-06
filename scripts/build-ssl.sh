#!/usr/bin/env bash
# Copyright 2016 Yash D. Saraf
# This file is part of BB-Bot.

# BB-Bot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# BB-Bot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with BB-Bot.  If not, see <http://www.gnu.org/licenses/>.

. ./toolchain-exports.sh

CURRDIR=$PWD
cd "`dirname $0`/../wolfssl"
for toolc in $ARMMUSL $X86MUSL $MIPSMUSL $MIPSEB
do
	_host=$(find $toolc/bin -name "*rorschack*gcc" | sed 's/.*\///;s/-gcc//')

	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib CC=$_host'-cc' CFLAGS="-Os -static -fomit-frame-pointer -falign-functions=1 \
	-falign-labels=1 -falign-loops=1 -falign-jumps=1 -ffunction-sections -fdata-sections" \
	./configure --host=$_host --enable-static --enable-singlethreaded --enable-openssh --disable-shared  \
	C_EXTRA_FLAGS="-DWOLFSSL_STATIC_RSA" >/dev/null || exit $?

	echo "Building $(cut -d- -f1 <<< $_host) ssl_helper--"
	make clean >/dev/null
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib make -j$CORES &>/dev/null

	cd ssl_helper-wolfssl

	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-gcc' -Os -Wall -I.. -c ssl_helper.c -o ssl_helper.o >/dev/null
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-gcc' -static -Wl,--start-group ssl_helper.o -lm ../src/.libs/libwolfssl.a -Wl,--end-group -o ssl_helper >/dev/null
	PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib $_host'-strip' ssl_helper >/dev/null
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
