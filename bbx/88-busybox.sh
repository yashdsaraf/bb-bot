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

file_list="
bin/busybox
xbin/busybox
vendor/bin/busybox
vendor/xbin/busybox
bin/ssl_helper
xbin/ssl_helper
vendor/bin/ssl_helper
vendor/xbin/ssl_helper
etc/passwd
etc/group
"

case "$1" in
    backup)
        for file in $file_list
        do
            file=$S/$file
            if [ -e $file ]
                then
                echo "$(date)  Backing up $file --" >> $LOGFILE
                backup_file $file
            fi
        done
    ;;
    restore)
        for file in $file_list
        do
            file=$S/$file
            if [ -e "$C/$file" ]
                then
                echo "$(date)  Restoring $file --" >> $LOGFILE
                restore_file $file
                if [ "${file##*/}" == "busybox" ]
                    then
                    for applet in `$file --list`
                    do
                        appletToInstall="${file%/*}/$applet"
                        ln -sf $file $appletToInstall
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
