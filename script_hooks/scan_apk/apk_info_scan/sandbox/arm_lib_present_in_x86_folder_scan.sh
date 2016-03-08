#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2

read_elf=/home/Git-Apk/.git/hooks/apk_info_scan/arm-none-linux-gnueabi-readelf
x86_lib_folder=$apk_uzipped_folder/lib/x86

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


#main: loop each so in X86 lib folder to check if it is for ARM
has_arm_so=$(has_any_so_for_arm "ARM")

if [ "TRUE" = "$has_arm_so" ]; then
    printf "$1:ARM lib is present in X86 folder!\n"|tee new.log
fi

