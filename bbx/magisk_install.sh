#!/sbin/sh

OUTFD=$1
MODID=bbxyds

ui_print() {
    if $BOOTMODE
        then echo "$1"
    else
        echo -e "ui_print $1\n
        ui_print" >> /proc/self/fd/$OUTFD
    fi
    echo -e "$1" >> $LOGFILE
}

require_new_magisk() {
    ui_print "***********************************"
    ui_print "! $MAGISKBIN isn't setup properly!"
    ui_print "! Please install Magisk v13.1+!"
    ui_print "***********************************"
    if $BOOTMODE
        then exit 1
    else
        ui_print "Falling back to normal installation --"
    fi
}

log_vars() {
    while [ ! -z $1 ]
    do
        name=$1
        value="$(eval echo \$$name)"
        echo "$name=\"$value\"" >> $INSTALLER/magisk_vars
        shift
    done
}

error() {
    local ERRSTAT=$?
    if [ $ERRSTAT -eq 0 ]
        then sleep 0.5
        return
    fi
    ui_print "  "
    ui_print " ***Abort!!*** "
    ui_print "Cause: $1"
    [ ! -z $LOGFILE ] && ui_print "Check $LOGFILE for errors"
    if [ "$_mounted" == "no" ]
        then umount /system
    fi
    exit "$ERRSTAT"
}

if [ ! -z $2 ] && [ "$2" == "cleanup" ]
    then
    if . $INSTALLER/magisk_vars
        then
        . $MAGISKBIN/util_functions.sh
        $MAGISKBIN/magisk --umountimg $MOUNTPATH $MAGISKLOOP
        rmdir $MOUNTPATH

        # Shrink the image if possible
        image_size_check $IMG
        newSizeM=$((curUsedM / 32 * 32 + 64))
        if [ $curSizeM -gt $newSizeM ]; then
          ui_print "Shrinking $IMG to ${newSizeM}M --"
          $MAGISKBIN/magisk --resizeimg $IMG $newSizeM
        fi

        $BOOTMODE || recovery_cleanup
    else ui_print "Warning: Magisk cleanup failed!"
    fi
    rm $INSTALLER/magisk_vars
    rm -f $0
    exit 0
fi

if [ -d $MAGISKBIN -a -x $MAGISKBIN/magisk -a -f $MAGISKBIN/util_functions.sh ]
    then
    . $MAGISKBIN/util_functions.sh

    if [ ! -z $SCRIPT_VERSION -a $SCRIPT_VERSION -ge 1310 ]
        then
        MODPATH=$MOUNTPATH/$MODID

        ui_print "  "
        ui_print "******************************"
        ui_print "Powered by Magisk (@topjohnwu)"
        ui_print "******************************"

        if $BOOTMODE
            then
            is_mounted /magisk
            error "Magisk is not activated"
        fi

        request_size_check $INSTALLER

        $BOOTMODE || recovery_actions

        if [ -f "$IMG" ]
            then
            ui_print "$IMG detected --"
            image_size_check $IMG
            if [ "$reqSizeM" -gt "$curFreeM" ]
                then
                newSizeM=$(((reqSizeM + curUsedM) / 32 * 32 + 64))
                ui_print "Resizing $IMG to ${newSizeM}M --"
                $MAGISKBIN/magisk --resizeimg $IMG $newSizeM
            fi
        else
            newSizeM=$((reqSizeM / 32 * 32 + 64));
            ui_print "Creating $IMG with size ${newSizeM}M --"
            $MAGISKBIN/magisk --createimg $IMG $newSizeM
        fi

        ui_print "Mounting $IMG to $MOUNTPATH --"
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
            ui_print "*****Error while mounting $IMG to $MOUNTPATH*****"
            ui_print "Falling back to normal installation --"
        fi
        log_vars "MAGISKLOOP" "OLD_LD_PATH" "OLD_PATH" "curUsedM" "curSizeM"
    else require_new_magisk
    fi
else require_new_magisk
fi