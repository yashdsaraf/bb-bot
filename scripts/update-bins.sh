#!/usr/bin/env bash

EXTRA=
i=
CURRDIR=$PWD
cd "`dirname $0`/../bbx"
for i in arm mips x86 mipseb
do
	echo $i
	echo "======================================================"
	cd Bins/$i
	( rm busybox*
	rm ssl_helper ) 2>/dev/null
	cp -v ../../../out/ssl_helper-$i ssl_helper
	if [[ $i != "mipseb" ]]
	then
		cat > "bins.md5" <<EOF
$(md5sum ssl_helper)
$(md5sum xzdec)
EOF
	fi
	for f in $(ls ../../../out/busybox-${i}{64,_64,}-*)
	do
		[[ $f =~ "nosel" ]] || EXTRA="-sel"
		[[ $f =~ "64" ]] && EXTRA="64$EXTRA"
		cp -v $f "busybox$EXTRA"
		xz -eq9 "busybox$EXTRA"
		rm "busybox$EXTRA" 2>/dev/null
		[[ $i != "mipseb" ]] &&
		echo "$(md5sum busybox$EXTRA.xz)" >> "bins.md5"
		EXTRA=
	done 2>/dev/null
	cp ../../../out/ssl_helper-$i ssl_helper 2>/dev/null
	echo "======================================================"
	echo ""
	# [[ $i != "mipseb" ]] && sed -i "s/  /=/g" bins.md5
	cd ../..
done
cd $CURRDIR
