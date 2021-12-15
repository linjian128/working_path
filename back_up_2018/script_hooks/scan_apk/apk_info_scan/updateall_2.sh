#!/bin/bash


git_dir="/home/Git-Apk"
counter=0
for apk in `ls ${git_dir}/All_Apk/*.apk`
    do
        apk_name=`basename $apk`
        printf "$apk_name \n"
        if [ -f ${git_dir}/All_Apk/$apk_name ]; then
            unzip ${git_dir}/All_Apk/$apk_name -d ${git_dir}/.git/hooks/apk_info_scan/data/$apk_name 

            bb_protection_scan.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/data/$apk_name
            x86_lib_missing.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/data/$apk_name

            apk_info=$(grep -c "Yes" ${git_dir}/.git/hooks/apk_info_scan/data/$apk_name/apk_info)
            if test $apk_info -le 0
            then
                rm -rf ${git_dir}/.git/hooks/apk_info_scan/data/$apk_name
            fi
        fi
    done
