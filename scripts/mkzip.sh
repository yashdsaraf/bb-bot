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

# FLASHABLE ZIP CREATION
SCRIPTDIR=$(realpath `dirname $0`)
SIGNAPKDIR=$SCRIPTDIR/signapk
cd "$SCRIPTDIR/../bbx"
PEM=$SIGNAPKDIR/certificate.pem
PK8=$SIGNAPKDIR/key.pk8
SIGNAPKJAR=$SIGNAPKDIR/signapk.jar # Provided by https://github.com/appium/sign
# Provided by https://github.com/omnirom/android_packages_apps_OpenDelta
ZIPADJUST=$SIGNAPKDIR/zipadjust
MINSIGNAPKJAR=$SIGNAPKDIR/minsignapk.jar

mkzip() {
    ZIPNAME="Busybox-$1.zip"
    7za a -tzip -mx=0 $ZIPNAME * >/dev/null
    # $ZIPALIGN -f -v 4 $ZIPNAME $ZIPNAME.aligned
    # mv -fv $ZIPNAME.aligned $ZIPNAME
    java -jar $SIGNAPKJAR $PEM $PK8 $ZIPNAME $ZIPNAME.signed
    $ZIPADJUST $ZIPNAME.signed $ZIPNAME
    java -jar $MINSIGNAPKJAR $PEM $PK8 $ZIPNAME $ZIPNAME.signed
    mv $ZIPNAME.signed ../out/$ZIPNAME
    rm $ZIPNAME
}

mkdir -p workspace
cd workspace
# for i in arm:arm64 x86:x86_64 mips:mips64
# do
i=$TO_BUILD
[[ $i == "mipseb" ]] && exit

# echo -e "\\n$i\\n"
echo "Zipping files --"
cp ../addusergroup.sh ../88-busybox.sh ../magisk/module.prop .
sed -i -e "s|^version=.*|version=v$VER|;s|^versionCode=.*|versionCode=$(tr -d '[:alpha:].-' <<< $VER)|"\
     module.prop
if [[ $i == "boxemup" ]]
    then
    cp -r ../AIO/META-INF .
    cat ../common_install_code.sh >> META-INF/com/google/android/update-binary
    sed -i -e "s|^STATUS=.*|STATUS=\"$STATUS\"|;s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|"\
     META-INF/com/google/android/update-binary
    for i in arm x86 mips
    do cp -r ../Bins/$i .
    done
    mkzip $VER-UNIVERSAL
    rm -rf *
    cp -r ../cleaner/META-INF .
    mkzip CLEANER
else
    ARCH=${i% *}
    ARCH64=${i#* }
    cp -r ../META-INF ../Bins/$ARCH/* .
    cat ../common_install_code.sh >> META-INF/com/google/android/update-binary
    sed -i -e "s|^ARCH=.*|ARCH=$ARCH|;s|^ARCH64=.*|ARCH64=$ARCH64|;s|^STATUS=.*|STATUS=\"$STATUS\"|;\
    s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|" META-INF/com/google/android/update-binary $SCRIPTDIR/SEE.template
    mkzip $VER-$(tr 'a-z' 'A-Z' <<< $ARCH)
    echo "Creating self extracting script --"
    rm -r bins.md5 META-INF xzdec
    unxz *xz
    7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on $TEMP_DIR/bbx.7z * >/dev/null
    . $SCRIPTDIR/mkSEE.sh
fi
# done
# rm -rf *
