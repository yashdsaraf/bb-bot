#!/sbin/sh

BOOTMODE=$1
OUTFD=$2
LOGFILE=$3
INSTALLDIR=$4
MOUNTPATH=/magisk
IMG=/data/magisk.img
if $BOOTMODE
    then
    MOUNTPATH=/dev/magisk_merge
    IMG=/data/magisk_merge.img
fi
MAGISKBIN=/data/magisk
MODID=bbxyds

ui_print_() {
    if $BOOTMODE
        then echo "$1"
    else
        echo -e "ui_print $1\n
        ui_print" >> /proc/self/fd/$OUTFD
    fi
    echo -e "$1" >> $LOGFILE
}

require_new_magisk() {
    ui_print_ "***********************************"
    ui_print_ "! $MAGISKBIN isn't setup properly!"
    ui_print_ "! Please install Magisk v13.1+!"
    ui_print_ "***********************************"
    if $BOOTMODE
        then exit 1
    else
        ui_print_ "Falling back to normal installation --"
    fi
}

error() {
    local ERRSTAT=$?
    if [ $ERRSTAT -eq 0 ]
        then sleep 0.5
        return
    fi
    ui_print_ "  "
    ui_print_ " ***Abort!!*** "
    ui_print_ "Cause: $1"
    [ ! -z $LOGFILE ] && ui_print_ "Check $LOGFILE for errors"
    if [ "$_mounted" == "no" ]
        then umount /system
    fi
    exit "$ERRSTAT"
}

if [ -d $MAGISKBIN -a -x $MAGISKBIN/magisk -a -f $MAGISKBIN/util_functions.sh ]
    then
    . $MAGISKBIN/util_functions.sh

    if [ ! -z $SCRIPT_VERSION -a $SCRIPT_VERSION -ge 1310 ]
        then
        MODPATH=$MOUNTPATH/$MODID

        ui_print_ "  "
        ui_print_ "******************************"
        ui_print_ "Powered by Magisk (@topjohnwu)"
        ui_print_ "******************************"

        if $BOOTMODE
            then
            is_mounted /magisk
            error "Magisk is not activated"
        fi

        ui_print_ "Extracting module.prop --"
        unzip -o "$BBZIP" module.prop >/dev/null
        error "Error while extracting files"
        request_size_check $INSTALLER

        $BOOTMODE || recovery_actions

        if [ -f "$IMG" ]
            then
            ui_print_ "$IMG detected --"
            image_size_check $IMG
            if [ "$reqSizeM" -gt "$curFreeM" ]
                then
                newSizeM=$(((reqSizeM + curUsedM) / 32 * 32 + 64))
                ui_print_ "Resizing $IMG to ${newSizeM}M --"
                $MAGISKBIN/magisk --resizeimg $IMG $newSizeM
            fi
        else
            newSizeM=$((reqSizeM / 32 * 32 + 64));
            ui_print_ "Creating $IMG with size ${newSizeM}M --"
            $MAGISKBIN/magisk --createimg $IMG $newSizeM
        fi

        ui_print_ "Mounting $IMG to $MOUNTPATH --"
        MAGISKLOOP=`$MAGISKBIN/magisk --mountimg $IMG $MOUNTPATH`
        if is_mounted $MOUNTPATH
            then
            rm -rf $MODPATH 2>/dev/null
            if [ $INSTALLDIR == 'none' ]
                then
                INSTALLDIR=$MODPATH/system/xbin
                mkdir -p $INSTALLDIR
            fi
            touch $MODPATH/auto_mount
            cp -af $INSTALLER/module.prop $MODPATH/module.prop
            if $BOOTMODE
                then
                mktouch /magisk/$MODID/update
                cp -af $MODPATH/module.prop /magisk/$MODID/module.prop
            fi
            set_perm_recursive $MODPATH 0 0 0755 0644
            echo $INSTALLDIR
        elif $BOOTMODE
            then false
            error "$IMG mount failed"
        else
            ui_print_ "*****Error while mounting $IMG to $MOUNTPATH*****"
            ui_print_ "Falling back to normal installation --"
        fi
    else require_new_magisk
    fi
else require_new_magisk
fi