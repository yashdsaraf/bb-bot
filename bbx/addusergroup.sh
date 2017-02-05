_passwd=$etc/passwd
_group=$etc/group

addu() {
	if [ ! -z $4 ]
	then _shell=$4
	else _shell=$INSTALLDIR/false
	fi

	echo "${2}:x:${1}:${1}::${3}:$_shell" >> $_passwd
}

addg() {
	echo "${2}:x:${1}:${2}" >> $_group
}

addug() {
    grep ^$2: $_group || addg $1 $2 >/dev/null 2>&1
    grep ^$2: $_passwd || addu $* >/dev/null 2>&1
}

[ ! -f $_passwd ] && touch $_passwd
[ ! -f $_group ] && touch $_group

user_name_id_list="
1000-system
1001-radio
1002-bluetooth
1003-graphics
1004-input
1005-audio
1006-camera
1007-log
1008-compass
1009-mount
1010-wifi
1011-adb
1012-install
1013-media
1014-dhcp
1015-sdcard_rw
1016-vpn
1017-keystore
1018-usb
1019-drm
1020-mdnsr
1021-gps
1023-media_rw
1024-mtp
1026-drmrpc
1027-nfc
1028-sdcard_r
1029-clat
1030-loop_radio
1031-mediadrm
1032-package_info
1033-sdcard_pics
1034-sdcard_av
1035-sdcard_all
1036-logd
1037-shared_relro
1038-dbus
1039-tlsdate
1040-mediaex
1041-audioserver
1042-metrics_coll
1043-metricsd
1044-webserv
1045-debuggerd
1046-mediacodec
1047-cameraserver
1048-firewall
1049-trunks
1050-nvram
1051-dns
1052-dns_tether
1053-webview_zygote
2000-shell
2001-cache
2002-diag
3001-net_bt_admin
3002-net_bt
3003-inet
3004-net_raw
3005-net_admin
3006-net_bw_stats
3007-net_bw_acct
3008-net_bt_stack
3009-readproc
3010-wakelock
9997-everybody
9998-misc
9999-nobody
"

addug 0 root /data/local/cron /system/bin/sh

for i in $user_name_id_list
do
	addug ${i%-*} ${i#*-} /system
done
