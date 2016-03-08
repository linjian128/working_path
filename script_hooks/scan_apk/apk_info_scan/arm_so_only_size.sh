#!/bin/bash


git_dir="/home/Git-Apk"
for apk in `ls ${git_dir}/All_Apk/*.apk`
do
    apk_name=`basename $apk`
    printf "$apk_name \n"
    if [ -f ${git_dir}/All_Apk/$apk_name ]; then
        unzip ${git_dir}/All_Apk/$apk_name -d ${git_dir}/.git/hooks/apk_info_scan/$apk_name 


#        apk_info_scan.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/$apk_name
        rm -rf ${git_dir}/.git/hooks/apk_info_scan/$apk_name
    fi
done
