#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2


function has_specific_file()
{
    local specific_file=$1
    local folder=$2
    
    find_result=`find $specific_folder -name $specific_file`

    if [[ -z $find_result ]]; then
    printf "FALSE"
    return 0;
    fi

    printf "TRUE"
}


#main: loop each so in X86 lib folder to check if it is for ARM
has_target=$(has_specific_file "DexToLoad.apk" "$2/asset")
if [ "TRUE" = "$has_target" ]; then
    printf "$1: is NQ Shield \n"|tee new.log
else
    has_target=$(has_specific_file "libnqshield.so" "$2/lib")
    if [ "TRUE" = "$has_target" ]; then
    printf "$1: is NQ shield \n"|tee new.log
    fi 
fi

