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



read_elf=readelf
x86_lib_folder=

function has_any_so_for_arm()
{
    local ARCH=ARM
    local sox=""
    for sox in `find $x86_lib_folder -name "*.so"`
    do

        local result=`$read_elf -h $sox|gawk '/'$ARCH'/ {print "TRUE"}'`
        if [ "TRUE" = "$result" ]; then
            printf "$result"
            return 0
        fi

    done
}


#main: loop each so for ARM in X86 lib folder
has_arm_so=$(has_any_so_for_arm "ARM")

if [ "TRUE" = "$has_arm_so" ]; then
    printf "ARM lib is present in X86 folder!\n"
fi

