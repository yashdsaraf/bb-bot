
OPFD=$2
BBZIP=$3
INSTALLDIR="none"
DATE=
STATUS=
VER=
SELINUXPRESENT=0
TMPDIR=/dev/tmp
INSTALLER=$TMPDIR/install

ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true || BOOTMODE=false
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true

ui_print_() {
    if $BOOTMODE
        then echo "$1"
    else
        echo -e "ui_print $1\n
        ui_print" >> /proc/self/fd/$OPFD
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

is_mounted() {
    grep "$1" /proc/mounts >/dev/null 2>&1
    return $?
}

mount_() {
    ( mount $* || /sbin/mount $* || toolbox mount $* ||
        toybox mount $* || return 1 ) >/dev/null 2>&1
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

set_permissions() {
    chmod $2 $1
    if ! chown $3:$4 $1 2>/dev/null
        then chown $3.$4 $1 2>/dev/null
    fi
    if [ $SELINUXPRESENT -eq 1 ]
        then chcon $5 $1
    fi
}

#embedded mode support
if readlink /proc/$$/fd/$OPFD 2>/dev/null | grep /tmp >/dev/null
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

mount_ /data

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

LOGFILE=$SDCARD/BusyBox-YDS-installer.log
echo "#`date`
#Ignore umount errors!" > $LOGFILE
exec 2>>$LOGFILE

print_banner

ui_print_ "Mounting /system --"

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

ui_print_ "Checking Architecture --"

FOUNDARCH="`grep -Eo "ro.product.cpu.abi(2)?=.+" /system/build.prop /default.prop 2>/dev/null | grep -Eo "[^=]*$" | head -n1`"

check_arch

# Temporary hack around for aarch64 segfaulting bb
if [ "$ARCH" == "arm" -a "$BBFILE" == "busybox64" ]
    then BBFILE=busybox
fi

ui_print_ "Checking if busybox needs to have SELinux support --"

API=`grep -E "ro.build.version.sdk=.+" /system/build.prop /default.prop 2>/dev/null | grep -Eo -m1 "[0-9]{2}"`

SELSTAT="DISABLED"
if [ -e /sys/fs/selinux/enforce ]
    then
    SELSTAT="ENABLED"
    SELINUXPRESENT=1
fi

# Read and parse bbx.conf if present
for i in /sdcard /data /cache
do
    if [ ! -f $i/bbx.conf ]
        then
        continue
    fi
    ui_print_ "Found $i/bbx.conf --"
    for line in `cat $i/bbx.conf`
    do
        option=${line%=*}
        value=${line#*=}
        case $option in
            selinux)
                case $value in
                    0) SELSTAT="DISABLED (user override)"
                    ;;
                    1) SELSTAT="ENABLED (user override)"
                    ;;
                    *) ui_print_ "Invalid option set for 'selinux' => $value (should be 0 or 1)"
                    ;;
                esac
            ;;
            noclean)
                NOCLEAN=1
            ;;
            installdir)
                if [ -z $value ]
                    then ui_print_ "Installation directory cannot be empty"
                    continue
                fi
                if ! [ -e $value ]
                    then mkdir $value
                    error "Error while creating $value"
                    set_permissions $value 0755 0 0 u:object_r:system_file:s0
                    INSTALLDIR=$value
                elif ! [ -d $value -a -w $value ]
                    then ui_print_ "Directory not accessible => $value"
                else INSTALLDIR=$value
                fi
            ;;
            *) ui_print_ "Invalid entry in config => $option"
            ;;
        esac
    done
    break
done
unset i

BBSEL=
if echo "$SELSTAT" | grep ENABLED >/dev/null 2>&1
    then
    BBSEL=-sel
fi

ui_print_ "  "
ui_print_ "SELinux support is $SELSTAT --"

BBFILE="${BBFILE}${BBSEL}.xz"
ui_print_ "Extracting files --"
rm -rf $TMPDIR 2>/dev/null
mkdir -p $INSTALLER
cd $INSTALLER
unzip_files >/dev/null
error "Error while extracting files"
ui_print_ "Checking md5sums of extracted bins --"
for i in $BBFILE ssl_helper xzdec
do
    [ -e $i ]
    error "Error while unzipping $i from $BBZIP"
    grep "$(md5sum $i)" bins.md5 >/dev/null 2>&1
    error "Error while checking md5sum of $i"
done
unset i
set_permissions xzdec 0555 0 2000 u:object_r:system_file:s0
./xzdec $BBFILE > busybox
set_permissions ssl_helper 0555 0 2000 u:object_r:system_file:s0
set_permissions busybox 0555 0 2000 u:object_r:system_file:s0
rm $BBFILE xzdec

SUIMG=$(
    ls /data/su.img || ls /cache/su.img
) 2>/dev/null

if [ ! -z "$SUIMG" ]
    then
    SULOOPDEV=$(mount_systemless $SUIMG "/su")
    ui_print_ "Systemless root detected --"
fi

if [ -f /data/magisk.img ]
    then
    ui_print_ "Magisk detected --"
    MOUNTPATH=/magisk
    IMG=/data/magisk.img
    if $BOOTMODE
        then
        MOUNTPATH=/dev/magisk_merge
        IMG=/data/magisk_merge.img
    fi
    MAGISKBIN=/data/magisk
    MODID=bbxyds
    if [ -d $MAGISKBIN -a -f $MAGISKBIN/magisk -a -f $MAGISKBIN/util_functions.sh ]
        then
        OUTFD=$OPFD
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
                MAGISKINSTALL=true
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
elif $BOOTMODE
    then false
    error "Magisk is not installed" 
fi

ui_print_ "  "

POSSIBLE_INSTALLDIRS="/su/xbin /system/xbin /system/vendor/bin /vendor/bin"
if [ $INSTALLDIR == "none" ]
    then
    for dir in $POSSIBLE_INSTALLDIRS
    do
        if [ -d $dir -a -w $dir ]
            then INSTALLDIR=$dir
            break
        fi
    done

    if [ $INSTALLDIR == "none" ]
        then
        INSTALLDIR="/system/xbin"
        mkdir $INSTALLDIR
        error "No accessible directory found for installation"
        set_permissions $INSTALLDIR 0755 0 0 u:object_r:system_file:s0
    fi
else USER_INSTALLDIR=$INSTALLDIR
fi

if [ -z $NOCLEAN ]
    then
    ui_print_ "Cleaning up older busybox versions (if any) --"
    TOTALSYMLINKS=0
    POSSIBLE_CLEANDIRS="$USER_INSTALLDIR /system/xbin /system/bin /su/xbin /su/bin /magisk/phh/bin /vendor/bin /system/vendor/bin"
    for dir in $POSSIBLE_CLEANDIRS
    do
        if [ ! -e $dir/busybox ]
            then continue
        fi
        ui_print_ "Found in $dir --"
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
        [ -e $dir/busybox ] && ui_print_ "Could **NOT** clean BusyBox in $dir --"
        TOTALSYMLINKS=$((TOTALSYMLINKS+count))
    done
    if [ $TOTALSYMLINKS -gt 0 ]
        then ui_print_ "Total applets removed => $TOTALSYMLINKS --"
        ui_print_ "  "
    fi
fi

ui_print_ "Copying Binary to $INSTALLDIR --"
cd $INSTALLDIR
cp -af $INSTALLER/busybox $INSTALLER/ssl_helper .
set_permissions ssl_helper 0555 0 2000 u:object_r:system_file:s0
set_permissions busybox 0555 0 2000 u:object_r:system_file:s0

ui_print_ "Setting up applets --"
for i in $(./busybox --list)
do
    # Only install applets which are not present in the system
    # Fixes the error of busybox applets being called instead of system's default applets
    # since magisk installs bins to /sbin which precedes /system
    if $MAGISKINSTALL && $MAGISKBIN/magisk --list | grep $i >/dev/null 2>&1
        then continue
    fi
    ./busybox ln -s busybox $i 2>/dev/null
    if [ ! -e $i ]
        then
        #Make wrapper scripts for applets if symlinking fails
        echo "#!$INSTALLDIR/busybox" > $i
        error "Error while setting up applets"
        set_permissions $i 0555 0 2000 u:object_r:system_file:s0
    fi
done
unset i

cd $INSTALLER
if [ -d /system/addon.d -a -w /system/addon.d ]
    then
    ui_print_ "Adding OTA survival script --"
    ./busybox unzip -o "$BBZIP" 88-busybox.sh >/dev/null
    set_permissions 88-busybox.sh 0755 0 0 u:object_r:system_file:s0
    mv 88-busybox.sh /system/addon.d
fi

ui_print_ "Adding common system users and groups --"
etc=$(
    ls -d /system/etc || ls -d /etc
) 2>/dev/null

if [ ! -z $etc -a -d $etc -a -w $etc ]
    then
    ./busybox unzip -o "$BBZIP" addusergroup.sh >/dev/null
    . ./addusergroup.sh || ui_print_ "Warning: Could not add common system users and groups!"
    rm addusergroup.sh
else ui_print_ "ETC directory is **NOT** accessible --"
fi

# cd to the root directory to avoid "device or resource busy" errors while unmounting 
cd /

ui_print_ "Unmounting /system --"
if [ ! -z $SULOOPDEV ]
    then umount /su
    losetup -d $SULOOPDEV
    rmdir /su
fi
if $MAGISKINSTALL
    then
    $MAGISKBIN/magisk --umountimg $MOUNTPATH $MAGISKLOOP
    rmdir $MOUNTPATH

    # Shrink the image if possible
    image_size_check $IMG
    newSizeM=$((curUsedM / 32 * 32 + 64))
    if [ $curSizeM -gt $newSizeM ]; then
      ui_print_ "Shrinking $IMG to ${newSizeM}M --"
      $MAGISKBIN/magisk --resizeimg $IMG $newSizeM
    fi

    $BOOTMODE || recovery_cleanup
else
    umount /system
fi
rm -rf $INSTALLER 2>/dev/null
ui_print_ "  "
ui_print_ "All DONE! -- Check $LOGFILE for more info"
sleep 0.5