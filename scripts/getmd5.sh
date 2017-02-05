#!/usr/bin/env bash
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
