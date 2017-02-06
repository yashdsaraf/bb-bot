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
cd "`dirname $0`/../bbx/Bins/x86"

xzdec busybox.xz > busybox
chmod +x busybox
NORMAL="$(./busybox --list)"
xzdec busybox-sel.xz > busybox
chmod +x busybox
SEL="$(./busybox --list)"
rm busybox
SEL=$(sort <(echo -e "$NORMAL\n$SEL") | uniq -u)
NORMAL="$(tr '\n' ' ' <<<$NORMAL | sed 's/ /, /g')"
SEL="$(tr '\n' ' ' <<<$SEL | sed 's/ /, /g')"
echo "Normal build --"
echo "===================================================================="
echo ${NORMAL:: -2}
echo ""
echo "SELinux build (excluding the above applets) --"
echo "===================================================================="
echo ${SEL:: -2}
cd $CURRDIR
