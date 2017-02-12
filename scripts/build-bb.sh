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

##Build busybox auto-magically
CURRDIR=$PWD
cd "`dirname $0`/../busybox"
current=nosel

build() {
    if [[ $1 == "all" ]]
        then
        build arm arm64 x86 x86_64 mips mips64 mipseb
        return 0
    fi

    while (( $# ))
    do
        if [[ $1 == "mipseb" && $current == "sel" ]]
            then
            shift 1
            continue
        fi
        : ${toolc:=$(eval echo \$`tr 'a-z' 'A-Z' <<< $1`)}
        sysr=$(find $toolc -name sysroot -type d)
        cross=`ls $toolc/bin | grep -E ".+-rorschack-linux-.+gcc$"\
        | awk -Fgcc '{print $1}'`
        sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"$sysr\"|" .config
        echo "Building $1 busybox--"
        make clean &>/dev/null
        PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib ARCH=$1 CROSS_COMPILE=$cross\
        CFLAGS="-Os -I$toolc/include" make -j$CORES >/dev/null 2>&1 || exit $?
        mv -v busybox ../out/busybox-$1-$current
        unset toolc
        shift 1
    done
}

make mrproper
echo -e "\nBuilding Non-SELinux busybox--\n"
cp conf_no_selinux .config
build $TO_BUILD
echo -e "\nBuilding SELinux busybox--\n"
current=sel
cp conf_selinux .config
build $TO_BUILD
