#!/usr/bin/env bash
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
