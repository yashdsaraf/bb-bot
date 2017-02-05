#!/usr/bin/env bash
. ./toolchain-exports.sh
##Build busybox auto-magically
CURRDIR=$PWD
cd "`dirname $0`/../busybox"
current=nosel

build() {
    if [[ $1 == "all" ]]
        then
        if [[ $current == "nosel" ]]
            then build arm arm64 x86 x86_64 mips mips64 mipseb
        else build arm arm64 x86 x86_64 mips mips64
        fi
        return 0
    fi

    while (( $# ))
    do
        : ${toolc:=$(eval echo \$`tr 'a-z' 'A-Z' <<< $1`)}
        sysr=$(find $toolc -name sysroot -type d)
        cross=`ls $toolc/bin | grep -E ".+-rorschack-linux-.+gcc$"\
        | awk -Fgcc '{print $1}'`
        sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"$sysr\"|" .config
        make clean
        PATH=$toolc/bin:$PATH LD_LIBRARY_PATH=$toolc/lib ARCH=$1 CROSS_COMPILE=$cross\
        CFLAGS="-Os -I$toolc/include" make -j$CORES
        exitstatus=$?
        [ $exitstatus -ne 0 ] && exit $exitstatus
        mv busybox ../out/busybox-$1-$current
        unset toolc
        shift 1
    done
}

make mrproper
cp conf_no_selinux .config
build $*
current=sel
cp conf_selinux .config
build $*
