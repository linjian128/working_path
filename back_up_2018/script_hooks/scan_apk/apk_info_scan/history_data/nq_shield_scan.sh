#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2

bb_so_dir=$apk_uzipped_folder/assets

#check if some rules mached, then log the APK name
if [ -e "$bb_so_dir/libsecexe.x86.so" ]||[ -e "$bb_so_dir/libsecmain.x86.so" ]; then
    printf "Bangbang Protected: Yes \n" |tee -a $apk_uzipped_folder/apk_info
else
    printf "Bangbang Protected: No \n" |tee -a $apk_uzipped_folder/apk_info
fi

if [ -e "$bb_so_dir/libnqshieldx86.so" ]; then
    printf "NQ Shield Protected: Yes \n" |tee -a $apk_uzipped_folder/apk_info
else
    printf "NQ Shield Protected: No \n" |tee -a $apk_uzipped_folder/apk_info
fi


#mysql -h10.239.51.146 -P3306  -uroot -pintel123 cv2 -e "update apk set lib_info_desc = '$BBP' where pkg_name = '$apk_name'"

