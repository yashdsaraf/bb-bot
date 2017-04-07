#!/usr/bin/env bash
# Copyright 2017 Yash D. Saraf
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

[[ "$TO_BUILD" == "boxemup" ]] && exit 0

CURRDIR=$PWD
cd "`dirname $0`"
export CORES="`lscpu | grep '^CPU(s)' | cut -d : -f2 | tr -d ' '`"
echo "Cores: $CORES"
git clone -b ${TO_BUILD% *} --single-branch https://github.com/yashdsaraf/toolchains || exit 1
cd toolchains
if [[ $TO_BUILD != "boxemup" ]]
    then
    for i in *.tar.xz
    do
        echo "Extracting $i--"
        # tar Jxf $i || exit 1
        ( xz -dcq -T$CORES $i | tar xf - ) || exit 1
    done
    for path in /usr/lib/x86_64-linux-gnu /usr/lib/i386-linux-gnu /usr/lib
    do
        if [[ -d $path ]]
            then sudo cp -avf lib/* $path
        fi
    done
    cp -r bin $TEMP_DIR
fi

# # install aclocal-1.15
# wget http://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
# tar xf automake*
# cd automake-1.15
# ( sh configure --prefix /usr/local
# sudo make -j$CORES install ) &>/dev/null
cd $CURRDIR
