#!/bin/bash
#set -x
LIB_LIST_FILE=library.list
if [[ -f $LIB_LIST_FILE ]]
then
	echo "pull library according to library.list"
else
	echo "please fetch the library.list file, containing the library list in default format according to lib_info.def"
	exit 
fi 

for non_ndk_lib in ` awk '/1},$/ {print substr($1,3,length($1)-4)}' library.list |tee non_ndk_library.list`
do
	if [[ -f $non_ndk_lib ]]
	then
		continue
	else
		adb pull /system/lib/arm/$non_ndk_lib .
	fi
	if [ $? -ne 0 ]
	then
		echo "pull $non_ndk_lib from device /system/lib/arm/ failed"
	fi
done

	

