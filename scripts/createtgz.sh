#!/usr/bin/env bash

DIR=$RANDOM
CURRDIR=$PWD
cd "`dirname $0`/../bbx/Bins"
mkdir $DIR
cd $DIR
for i in arm x86 mips mipseb
do
    echo -e "\\n$i\\n"
    cp ../$i/* .
    rm bins.md5 2>/dev/null
    unxz *.xz 2>/dev/null
    tar zcvf BusyBox-$VER-$(tr 'a-z' 'A-Z' <<<$i).tar.gz *
    mv *.tar.gz ../
    rm -rf *
done
cd ..
rmdir $DIR
cd $CURRDIR
