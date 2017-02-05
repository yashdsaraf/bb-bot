#!/usr/bin/env bash
CURRDIR=$PWD
cd "`dirname $0`"
URL="https://www.dropbox.com/sh/sovqvaf2p86og06/AAAyRYCRXHWfCy2uabMB34Qfa?dl=1"
wget $URL -O toolchains.zip || exit 1
unzip -o toolchains.zip '*.tar.xz' -d toolchains
cd toolchains
md5sum -c toolchains.md5 || exit 1
for i in *.tar.xz
do
	tar Jxf $i || exit 1
done
cd $CURRDIR
