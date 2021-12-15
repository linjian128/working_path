#!/bin/bash
#set -x
function readme
{
    echo "This script can help you to analyze non-ndk library usage in apks you specified."
    echo "Argument: The folder path which contains apks you want to analyze."
    echo "For example: ./process_depend_info.sh /home/user/workspace/apk/"
    echo "Result: Each apk's analysis result is stored in depend_result/apk_name."
    echo "prerequisite: readelf must be available on you machine"
}

if [[ $# -ne 2 ]]
then
    echo "usage: process_depend_info.sh arg"
    echo "arg is your apk folder's path"
    readme
    echo "exiting......"
    exit
fi

if [[ ! -d $1 ]]
then
    echo "Please specify your apk folder's path"
    echo "exiting......"
    readme
    exit
fi

which readelf>&/dev/null
if [[ $? -ne 0 ]]
then
    echo "It seems you don't have readelf, please install it first"
fi

FILE_PATH=$1
FILE_NAME=$2
ROOT="/home/Git-Apk/code_resource/script_hooks/import_update_apk/apk_non_NDK_pro"

APKS=$ROOT/apk_file
FOLDER=`basename $APKS`
UNPACKS=$ROOT/unpack
READELF=readelf
DUMPS=$ROOT/elf
RESULT=$ROOT/depend_result
DIRECTORY=$ROOT/depend_result/

rm -rf $UNPACKS
mkdir -p $UNPACKS

echo "unpacking..."

#count=0
#for apk in `cat $FILE_LIST`
#do
    #apkn=`basename $apk`
    mkdir -p $UNPACKS/$FILE_NAME
    unzip -q -o $FILE_PATH/$FILE_NAME -d $UNPACKS/$FILE_NAME
#    count=$(($count+1))
#done

rm -rf $DUMPS
mkdir $DUMPS

pushd $UNPACKS>/dev/null

echo "analyzing..."

for apk in `ls -d *.apk`
do
    rm -rf $DUMPS/$apk
    mkdir $DUMPS/$apk
    if [[ $? -eq 0 ]]
    then
        if [[ -d $apk/lib/armeabi ]]
        then
            pushd $apk/lib/armeabi > /dev/null
            for so in `ls *.so`
            do
                $READELF -d $so > $DUMPS/$apk/$so.dump
            done
                    popd > /dev/null
        fi
        if [[ -d $apk/lib/armeabi-v7a ]]
                    then
                    pushd $apk/lib/armeabi-v7a > /dev/null
                    for so in `ls *.so`
                    do
                    $READELF -d $so > $DUMPS/$apk/v7-$so.dump
                    done
                    popd > /dev/null
        fi
    fi
done

popd>/dev/null

declare -a ndk_lib=("libc.so" "libandroid.so" "libdl.so" "libEGL.so" "libGLESv1_CM.so" "libGLESv2.so" "libjnigraphics.so" "liblog.so" "libm.so" "libOpenSLES.so" "libstdc++.so" "libthread_db.so" "libz.so" "libOpenMAXAL.so")

rm -rf log*
rm -rf $RESULT
mkdir $RESULT

echo "Generating result..."

pushd $DUMPS>/dev/null
for apk in `ls -d *.apk`
do
    echo $apk
    pushd $apk>/dev/null
    for dump in `find . -name "*.so.dump"`
    do
	for lib in `grep "NEEDED" $dump | awk '{print substr($5, 2, length($5)-2)}'`
	    do
		lib=`basename $lib`
		ls $lib.dump&>/dev/null 
		if [[ $? -ne 0 ]]
		then
			ls v7-$lib.dump&>/dev/null
			if [[ $? -ne 0 ]]
			then
				echo $lib>>temp
			fi
		fi
	    done
	done
    
    if [[ -f temp ]]
    then    
        while read line
        do
            flag=0
            for v in "${ndk_lib[@]}"
            do
                if [[ $line = $v ]]
                then
                    flag=1
                    break
                fi
            done
            if [[ flag -eq 0 ]]
            then
                echo $line>>$RESULT/$apk.log
            fi
        done<temp
    if [[ -f $RESULT/$apk.log ]]
    then
        sort -u $RESULT/$apk.log > $RESULT/$apk
        rm -rf $RESULT/$apk.log
    fi
    rm -rf temp
    fi

    popd>/dev/null
done
popd>/dev/null

if [ "`ls -A $DIRECTORY`" != "" ]; then                                                  
	cp $ROOT/depend_result/* $ROOT/result -rf                               
	rm $ROOT/depend_result/* -rf
fi

rm -rf $UNPACKS
rm -rf $DUMPS

echo "Non-ndk library usage analysis is done, the result is stored in depend_result"
