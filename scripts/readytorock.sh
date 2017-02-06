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
./gettoolchains.sh
mkdir -p ../out
# install aclocal-1.15
wget http://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
tar xf automake*
cd automake-1.15
sh configure --prefix /usr/local > /dev/null
sudo make install
./build-ssl.sh
./build-bb.sh all
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
