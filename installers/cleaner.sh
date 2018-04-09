#!/sbin/sh
#BusyBox Cleaner
#by YashdSaraf@XDA

OPFD=$2
BBZIP=$3

ui_print() {
    echo -e "ui_print $1\n
    ui_print" >> /proc/self/fd/$OPFD
    echo -e "$1" >> $LOGFILE
}

error() {
    local ERRSTAT=$?
    if [ $ERRSTAT -ne 0 ]
        then
        ui_print "  "
        ui_print " ***Abort!!*** "
        ui_print "Cause: $1"
        [ ! -z $LOGFILE ] && ui_print "Check $LOGFILE for errors"
        [ "$_mounted" == "no" ] && umount /system
        exit "$ERRSTAT"
    else sleep 0.5
    fi
}

is_mounted() {
    grep "$1" /proc/mounts >/dev/null 2>&1
    return $?
}

mount_() {
    /sbin/mount $* || toolbox mount $* ||
    toybox mount $* || return 1
}

mount_systemless() {
    #Following code to mount su.img is borrowed from supersu update-binary
    if [ ! -d $2 ]
        then
        mkdir $2 2>/dev/null
        chmod 755 $2
    fi
    LOOPDEVICE=
    for LOOP in 0 1 2 3 4 5 6 7
    do
        if (! is_mounted $2)
            then LOOPDEVICE=/dev/block/loop$LOOP
            if [ ! -f "$LOOPDEVICE" ]
                then mknod $LOOPDEVICE b 7 $LOOP
            fi
            losetup $LOOPDEVICE $1
            if [ "$?" -eq "0" ]
                then
                mount_ -t ext4 -o loop $LOOPDEVICE $2
            fi
            if (is_mounted $2)
                then
                echo $LOOPDEVICE
                return 0
            fi
        fi
    done
    return 1
}

#embedded mode support
readlink /proc/$$/fd/$OPFD 2>/dev/null | grep /tmp >/dev/null
if [ "$?" -eq "0" ]
    then
    OPFD=0
    for FD in `ls /proc/$$/fd`
    do
        readlink /proc/$$/fd/$FD 2>/dev/null | grep pipe >/dev/null
        if [ "$?" -eq "0" ]
            then
            ps | grep " 3 $FD " | grep -v grep >/dev/null
              if [ "$?" -eq "0" ]
                  then
                OPFD=$FD
                break
            fi
        fi
    done
fi

( mount_ /data
mount_ /cache ) 2>/dev/null

#Redirect all errors to LOGFILE
for partition in /sdcard /data /cache
do
    if [ -w $partition ]
        then SDCARD=$partition
        break
    fi
done

if [ -z $SDCARD ]
    then false
    error "No accessible partition detected"
fi

LOGFILE=$SDCARD/BusyBox-cleaner.log
echo "#`date`
#Ignore umount errors!" > $LOGFILE
exec 2>>$LOGFILE

ui_print "================================================"
ui_print "                BusyBox Cleaner         "
ui_print "-- by @YashdSaraf https://xda-developers.com --"
ui_print "       ----- http://bit.ly/bbxyds -----   "
ui_print "==============================================="
ui_print "  "
sleep 1

ui_print "Mounting system --"

if (is_mounted /system)
    then
    mount_ -o rw,remount -t auto /system
    error "Error while mounting /system"
    _mounted="yes"
else
    mount_ -o rw -t auto /system
    error "Error while mounting /system"
    _mounted="no"
fi

# Read and parse bbx.conf if present
for i in /sdcard /data /cache
do
    if [ -f $i/bbx.conf ]
        then
        ui_print "Found $i/bbx.conf --"
        dir=$(grep installdir $i/bbx.conf | head -n1) 2>/dev/null
        dir=${dir#*=}
        if ! [ -z $dir ]
            then
            if ! [ -d $dir -a -w $dir ]
                then ui_print "Directory not accessible => $dir"
            else INSTALLDIR=$dir
            fi
        fi
    fi
done
unset i

SUIMG=$(
    ls /data/su.img || ls /cache/su.img
) 2>/dev/null
MAGISK=$(
    ls /data/magisk.img || ls /data/adb/magisk.img
) 2>/dev/null

if [ ! -z "$SUIMG" ]
    then
    SULOOPDEV=$(mount_systemless $SUIMG "/su")
    ui_print "Systemless root detected --"
elif [ -d /data/adb/su/xbin ]
    then ui_print "Systemless root detected (Running in SBIN mode) --"
fi

if [ ! -z "$MAGISK" ]
    then
    ui_print "Magisk detected --"
    MAGISKLOOPDEV=$(mount_systemless $MAGISK "/magisk")
fi

ui_print "Cleaning busybox --"
TOTALSYMLINKS=0
POSSIBLE_CLEANDIRS="/su/xbin /data/adb/su/xbin /system/xbin /system/vendor/bin /vendor/bin /data/adb/su/bin /system/bin /su/bin /magisk/phh/bin /su/xbin_bind /data/adb/su/xbin_bind $INSTALLDIR"
for dir in $POSSIBLE_CLEANDIRS
do
    if [ -e $dir/busybox ]
        then
        ui_print "Found in $dir --"
        cd $dir
        count=0
        for k in $(ls | grep -v busybox)
        do
            if [ "$k" -ef "busybox" -o -x $k -a "`head -n 1 $k`" == "#!$dir/busybox" ]
                then
                rm -f $k
                count=$((count+1))
            fi
        done
        rm -f busybox ssl_helper
        [ -e $dir/busybox ] && ui_print "Could **NOT** clean BusyBox in $dir --"
        TOTALSYMLINKS=$((TOTALSYMLINKS+count))
    fi
done
if [ $TOTALSYMLINKS -gt 0 ]
    then ui_print "Total applets removed => $TOTALSYMLINKS --"
    ui_print "  "
fi

if [ -d /magisk/bbxyds/system/xbin ]
    then
    ui_print "Setting up busybox in magisk for removal --"
    touch /magisk/bbxyds/remove
fi

# cd to the root directory to avoid "device or resource busy" errors while unmounting
cd /

ui_print "Unmounting /system --"
ui_print "  "
if [ ! -z $SULOOPDEV ]
    then umount /su
    losetup -d $SULOOPDEV
    rmdir /su
fi
if [ ! -z $MAGISKLOOPDEV ]
    then umount /magisk
    losetup -d $MAGISKLOOPDEV
    rmdir /magisk
fi
umount /system
ui_print "All DONE! -- Check $LOGFILE for more info"
ui_print "**************************************************"
ui_print "Uninstalling BusyBox might break some mods or apps"
ui_print "**************************************************"
