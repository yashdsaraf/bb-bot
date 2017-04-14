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

sudo apt-get update -qq
sudo apt-get install -qq p7zip-full realpath

if [[ $TO_BUILD == "boxemup" ]]
    then
    pip install -q requests termcolor
    exit 0
fi

sudo add-apt-repository ppa:jonathonf/automake -y
sudo apt-get update -qq
sudo apt-get install -qq automake-1.15

cd "$(realpath `dirname $0`)"
export CORES="`lscpu | grep '^CPU(s)' | cut -d : -f2 | tr -d ' '`"
echo "Cores: $CORES"
git clone -b ${TO_BUILD% *} --single-branch https://github.com/yashdsaraf/toolchains || exit 1
cd toolchains
if [[ $TO_BUILD != "boxemup" ]]
    then
    for i in *.tar.xz
    do
        echo "Extracting $i--"
        ( xz -dcq -T$CORES $i | tar xf - ) || exit 1
    done
    for path in /usr/lib/x86_64-linux-gnu /usr/lib/i386-linux-gnu /usr/lib
    do
        if [[ -d $path ]]
            then sudo cp -avf lib/* $path
        fi
    done
    if [[ -d bin ]]
        then cp -r bin $TEMP_DIR
    fi
fi
