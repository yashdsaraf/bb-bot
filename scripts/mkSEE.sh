#!/bin/bash

pad_zero() {
    if [ `wc -c <<< $1` -le 8 ]
        then echo $(pad_zero "0$1")
    else echo $1
    fi
}

gcd_ () {
    a=$1
    b=$2
    while :
    do
        if [[ $a == 0 || $b == 0 ]]
            then echo $(pad_zero $(expr $a + $b))
            break
        fi
        c=$(expr $a % $b)
        a=$b
        b=$c
    done
}

FILENAME="$SCRIPTDIR/../bbx/out/Busybox-$ARCH.bin"
BINDIR=$TEMP_DIR/bin
DECOMPRESSOR=$BINDIR/7zr
BBFILE=$TEMP_DIR/bbx.7z
DD=$BINDIR/dd.yds
cp $SCRIPTDIR/SEE.template $FILENAME

# Calculate static sizes first
byteCountDD=$(pad_zero `du -b $DD | awk '{print $1}'`)
byteCount7z=$(pad_zero `du -b $DECOMPRESSOR | awk '{print $1}'`)
byteCountBB=$(pad_zero `du -b $BBFILE | awk '{print $1}'`)

# Get the highest GCD (till 20 iterations) for greatest block size possible
# Higher the block size, higher the transfer speed of dd
blockSize=00000001
highestGCD=0
for i in `seq 0 20`
do
    temp=$(expr `du -b $FILENAME | awk '{print $1}'` + $i)
    currentBlockSize=`gcd_ $temp $byteCountDD`
    if [ $currentBlockSize -gt $blockSize ]
        then
        highestGCD=$i
        blockSize=$currentBlockSize
        # echo $i $blockSize $temp
    fi
done

# Append the script with stubs to make its size appropriate for the highest block size
if [ $highestGCD -gt 0 ]
    then for j in `seq $highestGCD`
    do
        echo -n "#" >> $FILENAME
    done
fi

bytesToSkipDD=$(pad_zero `du -b $FILENAME | awk '{print $1}'`)
bytesToSkip7z=$(pad_zero $(expr $bytesToSkipDD + $byteCountDD))
bytesToSkipBB=$(pad_zero $(expr $bytesToSkip7z + $byteCount7z))

# If block size was altered, adjust byte count and bytes to skip
if [ $blockSize -gt 1 ]
    then
    byteCountDD=$(pad_zero $(expr $byteCountDD / $blockSize))
    bytesToSkipDD=$(pad_zero $(expr $bytesToSkipDD / $blockSize))
fi

sed -i -e "s|^byteCountDD.*|byteCountDD=$byteCountDD|;
s|^byteCount7z.*|byteCount7z=$byteCount7z|;
s|^byteCountBB.*|byteCountBB=$byteCountBB|;
s|^blockSize.*|blockSize=$blockSize|;
s|^bytesToSkipDD.*|bytesToSkipDD=$bytesToSkipDD|;
s|^bytesToSkip7z.*|bytesToSkip7z=$bytesToSkip7z|;
s|^bytesToSkipBB.*|bytesToSkipBB=$bytesToSkipBB|" $FILENAME

#Append the files to the directory
cat $DD >> $FILENAME
cat $DECOMPRESSOR >> $FILENAME
cat $BBFILE >> $FILENAME
