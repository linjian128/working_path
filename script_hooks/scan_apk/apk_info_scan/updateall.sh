#!/bin/bash


git_dir="/home/Git-Apk"
for apk in `ls ${git_dir}/All_Apk/*.apk`
do
    apk_name=`basename $apk`
    printf "$apk_name \n"
    if [ -f ${git_dir}/All_Apk/$apk_name ]; then
        unzip ${git_dir}/All_Apk/$apk_name -d ${git_dir}/.git/hooks/apk_info_scan/$apk_name 

        apk_info_scan.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/$apk_name
        #bb_protection_scan.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/$apk_name
        #x86_lib_missing.sh $apk_name ${git_dir}/.git/hooks/apk_info_scan/$apk_name

        #apk_info=`cat ${git_dir}/.git/hooks/apk_info_scan/$apk_name/apk_info`
        #mysql -h10.239.51.146 -P3306  -uroot -pintel123 cv2 -e "update apk set lib_info_desc = '$apk_info' where pkg_name = '$apk_name'"
        rm -rf ${git_dir}/.git/hooks/apk_info_scan/$apk_name
    fi
done
