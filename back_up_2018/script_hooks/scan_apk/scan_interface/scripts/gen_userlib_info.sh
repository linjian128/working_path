#!/bin/bash
#set -x
if [[ $# -ne 2 ]]
then 
	echo "usage: ./xx.sh APK_DIR TOOLS_DIR/TOOLCHAIN_PREFIX"
	echo "exiting....."
	exit
fi

declare -i remote
remote=0

cd $1 > /dev/null 2>&1     
if [ $? -ne 0 ]
then
	echo "open $1 failed, assume it is a remote directory"
	remote=1
	if [[ $1 = '@' ]]
	then
		REMOTE_ADD=`cat ../../../../config.ini | grep -w "^GIT_REMOTE_URL" | awk -F "=" '{print $2}' | awk -F ":" '{print $1}'`
		REMOTE_DIR="`cat ../../../../config.ini | grep -w "^GIT_REMOTE_URL" | awk -F ":" '{print $2}'`/All_Apk"
	else
		echo $1 | grep @ | grep : > /dev/null
		if [ $? -ne 0 ]
		then 
			echo "$1 is not a legal remote directory"
			exit 1
		else
			REMOTE_ADD=${1%%:*}
			REMOTE_DIR=${1#*:}
		fi
	fi
	## formate directory name and check connection
	REMOTE_DIR=`ssh $REMOTE_ADD "cd $REMOTE_DIR && pwd"`

	APKS=./APK_list
	rm -rf $APKS
	mkdir $APKS
	echo "fetch apk file from $REMOTE_ADD:$REMOTE_DIR"
	for file in `ssh $REMOTE_ADD "ls $REMOTE_DIR"`
#	for file in `ssh $REMOTE_ADD "cd $REMOTE_DIR && ls co.*"`
	do
		touch $APKS/$file
	done
else
# Input directory can be relative or absolute, may or may not end with '/'
	APKS=$PWD
	cd - > /dev/null
fi


TOOLS_DIR=$2

UNPAPKS=./APK_unpack
rm -rf $UNPAPKS
mkdir -p $UNPAPKS
READELF=./APK_readelf
rm -rf $READELF
mkdir $READELF
OBJDUMP=./APK_objdump
rm -rf $OBJDUMP
mkdir $OBJDUMP

echo "use toolchain: $TOOLS_DIR"

declare -i count
count=0
for apkd in `ls $APKS/*.apk`
do
	apkn=`basename $apkd`
	#echo "get user lib information from $apkn"
	mkdir $UNPAPKS/$apkn
	
	if [[ $remote = 0 ]]
	then
		unzip -q -o $apkd -d $UNPAPKS/$apkn
	else
		scp -r $REMOTE_ADD:$REMOTE_DIR/$apkn .
		unzip -q -o ./$apkn -d $UNPAPKS/$apkn
	fi

	mkdir $READELF/$apkn
        mkdir $OBJDUMP/$apkn

	if [[ $? -eq 0 ]]
        then
                if [ -d $UNPAPKS/$apkn/lib/armeabi ]
                then
                        for so_d in `ls $UNPAPKS/$apkn/lib/armeabi/*.so`
                        do
                                so_n=`basename $so_d`
				file $so_d | grep "dynamically linked" > /dev/null
				if [[ $? -eq 0 ]]
				then
                                	$TOOLS_DIR-readelf -d $so_d > $READELF/$apkn/$so_n.elf  	2>>./LOG/damaged_lib
                                	$TOOLS_DIR-objdump -T $so_d > $OBJDUMP/$apkn/$so_n.dump  	2>>./LOG/damaged_lib
				fi
                        done
                fi
                if [ -d $UNPAPKS/$apkn/lib/armeabi-v7a ]
                then
                        for so_d in `ls $UNPAPKS/$apkn/lib/armeabi-v7a/*.so`
                        do
                                so_n=`basename $so_d`
				file $so_d | grep "dynamically linked" > /dev/null
				if [[ $? -eq 0 ]]
				then
                                	$TOOLS_DIR-readelf -d $so_d > $READELF/$apkn/v7-$so_n.elf	2>>./LOG/damaged_lib
                                	$TOOLS_DIR-objdump -T $so_d > $OBJDUMP/$apkn/v7-$so_n.dump	2>>./LOG/damaged_lib
				fi
                        done
                fi

        fi


	rm -rf $UNPAPKS/$apkn
	if [[ $remote = 1 ]]
	then
		rm -f ./$apkn
	fi

	count=$count+1
done

echo "totally unzip and read ARM native library information for $count apks"

exit
