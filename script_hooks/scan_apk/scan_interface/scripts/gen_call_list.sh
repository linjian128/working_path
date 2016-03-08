#!/bin/bash
#set -x
if [ $# -ne 3 ]
then
        echo "usage ./xx.sh elf_DIR objdump_DIR ndk_lib_func_DIR"
        echo "exiting..."
        exit 1
fi

READELF=$1
OBJDUMP=$2
API_DIR=$3

CALL_LIST=./report
NON_NDK_LIST_FILE=./LIB/non_ndk_library.list
rm -rf $CALL_LIST
mkdir -p $CALL_LIST

#declare -a ndk_lib=("libc.so" "libandroid.so" "libdl.so" "libEGL.so" "libGLESv1_CM.so" "libGLESv2.so" "libjnigraphics.so" "liblog.so" "libm.so" "libOpenSLES.so" "libstdc++.so" "libthread_db.so" "libz.so" "libOpenMAXAL.so")

NON_NDK_LIST=`cat $NON_NDK_LIST_FILE`
#declare -a non_ndk_lib=`cat $NON_NDK_LIST_FILE` 
#for val in $non_ndk_lib
#do 
#	echo $val
#done

if [ -f ./LOG/target ]
then
	rm -f ./LOG/target
fi

for apkd in `ls -d $READELF/*.apk`
do
    apkn=`basename $apkd`
	#echo "scan interface for $apkn"

	for elf_d in `find $apkd -name "*.elf"`
	do
		user_lib=`basename $elf_d | awk '{print substr($1,1,length($1)-4)}'`
		for libn in `grep "NEEDED" $elf_d | awk '{print substr($5,2,length($5)-2)}'`
		do
			flag=0
			ls $apkd/$libn.elf &> /dev/null		# screen out cross reference
			if [ $? -ne 0 ]
			then
				for v in $NON_NDK_LIST
				#for v in "${ndk_lib[@]}"
				do
					if [[ $libn = $v ]]
					then
						flag=1		
						## generate apk list that contain non-ndk libs
						echo -e "$apkn\t$v" >> ./LOG/target_apk
					#	scp zxia10x@gitserver:/share/Git-Apk/All_Apk/$apkn ~/Downloads/APKS/
						break
					fi
				done
				if [ $flag -eq 1 ]		# it is a non-ndk lib
				then
					for func in `grep "\*UND\*" $OBJDUMP/$apkn/$user_lib.dump | awk '{print substr($NF,1,length($NF))}' `	
					do
						cat $API_DIR/$libn.func | grep -w $func > /dev/null
						if [ $? -eq 0 ]
						then		
						 	 echo -e  "$func\t$apkn\t$user_lib" >> $CALL_LIST/$libn.call.list		## don't change output format, next will use this to gen frequence report
						fi
					done
				fi
			fi
		done	
	done

done

for clist in `ls $CALL_LIST/*.call.list`
do
	libn=`basename $clist .call.list`
	echo "generate interface frequency report for library $libn"
	cat $clist |awk '{print $1}' |sort |uniq -c |sort -rn > $CALL_LIST/$libn.report
done
