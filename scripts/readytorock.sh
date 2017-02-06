#!/usr/bin/env bash
set -e
VER="1.26.2-YDS"
STATUS="Stable"
DATE="`date +'%d %b/%y'`"
CORES="`lscpu | grep '^CPU(s)' | cut -d : -f2 | tr -d ' '`"
echo "Cores: $CORES"
export VER STATUS DATE CORES
CURRDIR=$PWD
cd "`dirname $0`"
if [[ ! -d ../busybox ]]
	then (cd .. && git clone https://github.com/yashdsaraf/busybox.git)
else
	cd ../busybox
	git pull
	cd "`dirname $0`"
fi
echo "Checking flex libs"
for path in /usr/lib /usr/lib/i386-linux-gnu
do
	if [[ -e $path/libfl.so ]]
	then echo "Found in $path"
		if [[ ! -e $path/libfl.so.2 ]]
			then sudo ln -s $path/libfl.so $path/libfl.so.2
		fi
	break
	fi
done
./gettoolchains.sh
./build-bb.sh all
./build-ssl.sh
./update-bins.sh
./createtgz.sh
./mkzip.sh
cd ../bbx/out
DIR=`date +'%b-%d-%y'`
mkdir -p $DIR
cd $DIR
mkdir -p Tars
cd Tars
mv ../../../Bins/*tar.gz .
cd ..
mv ../*zip .
cd $CURRDIR
