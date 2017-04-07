# OTA survival script for busybox by YashdSaraf@XDA
# For a sample script see
# https://github.com/LineageOS/android_vendor_cm/blob/cm-14.1/prebuilt/common/bin/backuptool.sh

# See https://github.com/LineageOS/android_vendor_cm/blob/cm-14.1/prebuilt/common/bin/backuptool.functions
. /tmp/backuptool.functions

SDCARD=$(
    ls -d /sdcard || ls -d /data || ls -d /cache
) 2>/dev/null
LOGFILE=$SDCARD/88busybox.log
exec 2>>$LOGFILE

[ -e /sys/fs/selinux/enforce ] && SELINUXPRESENT=1

file_list = "
/su/bin/busybox
/su/xbin/busybox
/magisk/phh/bin/busybox
$S/bin/busybox
$S/xbin/busybox
$S/etc/passwd
$S/etc/group
$S/etc/resolv.conf
"

case "$1" in
    backup)
        echo "$(date)  Backing up --" >> $LOGFILE
        for file in $file_list
        do
            if [ -e $file ]
                then backup_file $file
            fi
        done
    ;;
    restore)
        echo "$(date)  Restoring --" >> $LOGFILE
        for file in $file_list
        do
            if [ -e "$C/$file" -a -w "${file%/*}" ]
                then
                restore_flie $file
                if [ "${file##*/}" == "busybox" ]
                    then
                    for applet in `$file --list`
                    do
                        appletToInstall="${file%/*}/$applet"
                        ln -s $file $appletToInstall
                        if ! [ -e $appletToInstall ]
                            then
                            echo "#!$file" > $appletToInstall
                            chmod 0755 $appletToInstall
                            ( chown 0.2000 $appletToInstall || chown 0:2000 $appletToInstall ) 2>/dev/null
                            (( $SELINUXPRESENT )) && chcon u:object_r:system_file:s0 $appletToInstall
                        fi
                    done
                fi
            fi
        done
    ;;
esac
