#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2

bb_so_dir=$apk_uzipped_folder/assets

#check if some rules matched, then log the APK name
if [ -e "$bb_so_dir/libsecexe.x86.so" ]||[ -e "$bb_so_dir/libsecmain.x86.so" ]; then
    printf "Bangbang Protected: $1 \n"|tee tmp.txt
    printf "Bangbang Protected: Yes \n" |tee -a $apk_uzipped_folder/apk_info
    exit
else
    printf "Bangbang Protected: No \n" |tee -a $apk_uzipped_folder/apk_info
fi

