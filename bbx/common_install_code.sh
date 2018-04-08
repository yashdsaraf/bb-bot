
##################

# Index:

# 1. Load magisk util_functions if found
# 2. Mount /system
# 3. Detect device architecture
# 4. Read and interpret bbx.conf if found
# 5. Extract busybox and all other necessary bins to a temporary directory and set appropriate permissions
# 6. Mount systemless images for SuperSU and Magisk
# 7. Figure out an installation location
#   7.1 Go with the location mentioned in bbx.conf if found
#   7.2 Check for magisk and use it for installation if possible
#   7.3 Check for SuperSU and use it for installation if possible
#   7.4 Go with any of the possible installation directories
# 8. Clean busybox in all the possible directories (including the current installation directory)
# 9. Copy the binaries to installation directory
# 10. Add OTA survival script if possible
# 11. Add common users and groups
# 12. Unmount system and any other images we might've mounted

##################

# Magisk specific vars
MAGISK=false
MAGISKBIN=/data/adb/magisk
MAGISK_UTIL_FUNCTIONS=$MAGISKBIN/util_functions.sh

if [ -f $MAGISK_UTIL_FUNCTIONS ]
    then
    . $MAGISK_UTIL_FUNCTIONS
    MAGISK=true
fi

OPFD=$2
BBZIP=$3
INSTALLDIR="none"
DATE=
STATUS=
VER=
SELINUXPRESENT=0
TMPDIR=/dev/tmp
INSTALLER=$TMPDIR/install

# Add applets which should not be symlinked/installed to this list.
# Separate applets using a single space.
BLACKLISTED_APPLETS=" su "

is_blacklisted() {
    blacklisted=false
    for blacklisted_applet in $BLACKLISTED_APPLETS
    do
        if [ "$1" == "$blacklisted_applet" ]
        then
            blacklisted=true
            break
        fi
    done
    $blacklisted
}

ui_print() {
    echo -e "ui_print $1\n
    ui_print" >> /proc/self/fd/$OPFD
    echo -e "$1" >> $LOGFILE
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
    mkdir -p $2
    chmod 755 $2
    if [ ! -d $2 ]
        then
        return
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

require_new_magisk() {
    ui_print "*******************************"
    ui_print " Please install Magisk v15.0+! "
    ui_print "*******************************"
    exit 1
}

ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true || BOOTMODE=false
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true

if $BOOTMODE && ! $MAGISK
    then require_new_magisk
fi

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

ui_print "Mounting /system --"

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

ui_print "Checking Architecture --"

FOUNDARCH="`grep -Eo "ro.product.cpu.abi(2)?=.+" /system/build.prop /default.prop 2>/dev/null | grep -Eo "[^=]*$" | head -n1`"

check_arch

# Temporary hack around for aarch64 segfaulting bb
# if [ "$ARCH" == "arm" -a "$BBFILE" == "busybox64" ]
#     then BBFILE=busybox
# fi

ui_print "Checking if busybox needs to have SELinux support --"

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
    ui_print "Found $i/bbx.conf --"
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
                    *) ui_print "Invalid option set for 'selinux' => $value (should be 0 or 1)"
                    ;;
                esac
            ;;
            noclean)
                NOCLEAN=1
            ;;
            installdir)
                if [ -z $value ]
                    then ui_print "Installation directory cannot be empty"
                    continue
                fi
                if ! [ -e $value ]
                    then mkdir $value
                    error "Error while creating $value"
                    set_permissions $value 0755 0 0 u:object_r:system_file:s0
                    INSTALLDIR=$value
                elif ! [ -d $value -a -w $value ]
                    then ui_print "Directory not accessible => $value"
                else INSTALLDIR=$value
                fi
            ;;
            *) ui_print "Invalid entry in config => $option"
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

ui_print "  "
ui_print "SELinux support is $SELSTAT --"

BBFILE="${BBFILE}${BBSEL}.xz"
ui_print "Extracting files --"
rm -rf $TMPDIR 2>/dev/null
mkdir -p $INSTALLER
cd $INSTALLER
unzip_files >>$LOGFILE 2>&1
error "Error while extracting files"
ui_print "Checking md5sums of extracted bins --"
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

# Mount SuperSU if found

SUIMG=$(
    ls /data/su.img || ls /cache/su.img
) 2>/dev/null

if [ ! -z "$SUIMG" ]
    then
    SULOOPDEV=$(mount_systemless $SUIMG "/su")
    ui_print "Systemless root detected --"
elif [ -d /data/adb/su ]
    then ui_print "Systemless root detected (Running in SBIN mode) --"
fi

ui_print "  "

# Mount magisk if found

if $MAGISK
    then
    OUTFD=$OPFD
    MOUNTPATH=$TMPDIR/magisk_img
    get_outfd
    mount_partitions
    api_level_arch_detect
    $BOOTMODE && boot_actions || recovery_actions
    MIN_VER=`grep_prop minMagisk $INSTALLER/module.prop`
    [ ! -z $MAGISK_VER_CODE -a $MAGISK_VER_CODE -ge $MIN_VER ] || require_new_magisk
    MODID=`grep_prop id $INSTALLER/module.prop`
    MODPATH=$MOUNTPATH/$MODID

    ui_print "******************************"
    ui_print "Powered by Magisk (@topjohnwu)"
    ui_print "******************************"

    request_zip_size_check "$BBZIP"
    mount_magisk_img

    rm -rf $MODPATH 2>/dev/null
    mkdir -p $MODPATH

    if [ $INSTALLDIR == "none" ]
        then
        INSTALLDIR=$MODPATH/system/xbin
        mkdir -p $INSTALLDIR
    fi

    touch $MODPATH/auto_mount

    cp -af $INSTALLER/module.prop $MODPATH/module.prop
    if $BOOTMODE
        then
        # Update info for Magisk Manager
        mktouch /sbin/.core/img/$MODID/update
        cp -af $INSTALLER/module.prop /sbin/.core/img/$MODID/module.prop
    fi

    set_perm_recursive  $MODPATH  0  0  0755  0644

fi

POSSIBLE_INSTALLDIRS="/su/xbin /data/adb/su/xbin /system/xbin /system/vendor/bin /vendor/bin"
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
    ui_print "Cleaning older busybox versions (if any) --"
    TOTALSYMLINKS=0
    POSSIBLE_CLEANDIRS="$USER_INSTALLDIR $POSSIBLE_INSTALLDIRS /data/adb/su/bin /system/bin /su/bin /magisk/phh/bin /su/xbin_bind /data/adb/su/xbin_bind"
    for dir in $POSSIBLE_CLEANDIRS
    do
        if [ ! -e $dir/busybox ]
            then continue
        fi
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
    done
    if [ $TOTALSYMLINKS -gt 0 ]
        then ui_print "Total applets removed => $TOTALSYMLINKS --"
        ui_print "  "
    fi
fi

ui_print "Copying binary to $INSTALLDIR --"
cd $INSTALLDIR
cp -af $INSTALLER/busybox $INSTALLER/ssl_helper .
set_permissions ssl_helper 0555 0 2000 u:object_r:system_file:s0
set_permissions busybox 0555 0 2000 u:object_r:system_file:s0

ui_print "Setting up applets --"
for applet in $(./busybox --list)
do
    # Only install applets which are not present in the system
    # Fixes the error of busybox applets being called instead of system's default applets
    # since magisk installs bins to /sbin which precedes /system
    if $MAGISKINSTALL && $MAGISKBIN/magisk --list | grep $applet >/dev/null 2>&1
        then continue
    fi
    if (is_blacklisted $applet)
    then continue
    fi
    ./busybox ln -s busybox $applet 2>/dev/null
    if [ ! -e $applet ]
        then
        #Make wrapper scripts for applets if symlinking fails
        echo "#!$INSTALLDIR/busybox" > $applet
        error "Error while setting up applets"
        set_permissions $applet 0555 0 2000 u:object_r:system_file:s0
    fi
done

cd $INSTALLER
if [ -d /system/addon.d -a -w /system/addon.d ]
    then
    ui_print "Adding OTA survival script --"
    ./busybox unzip -o "$BBZIP" 88-busybox.sh >>$LOGFILE 2>&1
    set_permissions 88-busybox.sh 0755 0 0 u:object_r:system_file:s0
    mv 88-busybox.sh /system/addon.d
fi

ui_print "Adding common system users and groups --"
etc=$(
    ls -d /system/etc || ls -d /etc
) 2>/dev/null

if [ ! -z $etc -a -d $etc -a -w $etc ]
    then
    ./busybox unzip -o "$BBZIP" addusergroup.sh >>$LOGFILE 2>&1
    . ./addusergroup.sh || ui_print "Warning: Could not add common system users and groups!"
    rm addusergroup.sh
else ui_print "ETC directory is **NOT** accessible --"
fi

# cd to the root directory to avoid "device or resource busy" errors while unmounting
cd /

if [ ! -z $SULOOPDEV ]
    then umount /su
    losetup -d $SULOOPDEV
    rmdir /su
fi

ui_print "Unmounting /system --"

if $MAGISK
    then
    if ! $BOOTMODE
        then recovery_cleanup
    fi
else
    umount /system
fi

rm -rf $TMPDIR 2>/dev/null

ui_print "  "
ui_print "All DONE! -- Check $LOGFILE for more info"
sleep 0.5
