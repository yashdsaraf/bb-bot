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

#FLASHABLE ZIP CREATOR
CURRDIR=$PWD
cd "`dirname $0`/../bbx"
# SIGNAPKDIR=$(realpath ../../SignApk)
# ZIPALIGN=~/opt/android-sdk-linux/build-tools/25.0.2/zipalign
# PEM=$SIGNAPKDIR/certificate.pem
# PK8=$SIGNAPKDIR/testkey.pk8

mkzip() {
    ZIPNAME=$(realpath ../out)/Busybox-"$VER"-"$(tr 'a-z' 'A-Z' <<< $1)".zip
    7za a -tzip -r $ZIPNAME *
    # $ZIPALIGN -f -v 4 $ZIPNAME $ZIPNAME.aligned
    # mv -fv $ZIPNAME.aligned $ZIPNAME
    # java -Xms5g -Xmx5g -jar $SIGNAPKDIR/inc.signapk.jar -w $PEM $PK8 $ZIPNAME $ZIPNAME.signed
    # mv -fv $ZIPNAME.signed $ZIPNAME
}

mkdir -p workspace out
rm -rf out/*
cd workspace
for i in arm:arm64 x86:x86_64 mips:mips64; do
    echo -e "\\n$i\\n"
    rm -rf *
    ARCH=${i%:*}
    ARCH64=${i#*:}
    cp ../addusergroup.sh .
    cp -r ../META-INF .
    cp ../Bins/$ARCH/* .
    sed -i -e "s|^ARCH=.*|ARCH=$ARCH|;s|^ARCH64=.*|ARCH64=$ARCH64|;s|^STATUS=.*|STATUS=\"$STATUS\"|;\
    s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|" META-INF/com/google/android/update-binary
    mkzip $ARCH
    #7za a -tzip $(realpath ../out)/BusyBox-"$VER"-"$(tr 'a-z' 'A-Z' <<< $i)"-YDS.zip \
        #    META-INF busybox*
done

rm -rf *
echo -e "\\nALL-ARCHS\\n"
cp -r ../AIO/META-INF .
sed -i -e "s|^STATUS=.*|STATUS=\"$STATUS\"|;s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|"\
 META-INF/com/google/android/update-binary
cp ../addusergroup.sh .
for i in arm x86 mips; do
    cp -r ../Bins/$i .
done
mkzip Universal

rm -rf *
cd $CURRDIR
