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

CURRDIR=$PWD
cd "`dirname $0`"
URL="https://www.dropbox.com/sh/sovqvaf2p86og06/AAAyRYCRXHWfCy2uabMB34Qfa?dl=1"
wget $URL -O toolchains.zip || exit 1
unzip -o toolchains.zip '*.tar.xz' toolchains.md5 -d toolchains
cd toolchains
md5sum -c toolchains.md5 || exit 1
for i in *.tar.xz
do
	echo "Extracting $i--"
	tar Jxf $i || exit 1
done
for path in /usr/lib/x86_64-linux-gnu /usr/lib/i386-linux-gnu /usr/lib
do
	if [[ -d $path ]]
		then sudo cp -avf lib/* $path
	fi
done
cd $CURRDIR
