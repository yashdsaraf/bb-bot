#!/usr/bin/env bash

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
