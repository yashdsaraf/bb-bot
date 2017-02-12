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

CURRDIR=$PWD
cd "`dirname $0`/../bbx/Bins"
for i in arm x86 mips mipseb
do
    cd $i
    echo $(tr [a-z] [A-Z] <<<$i)
    echo "===================================================="
    for xz in *xz
    do
        echo "$(xzdec $xz | md5sum) ${xz/.xz}"
    done
    echo -e "====================================================\n"
    cd ..
done
cd $CURRDIR
