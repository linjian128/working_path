#!/bin/bash

git_dir=`cat ../../../config.ini | grep -w "^GIT_LOCAL_URL" | awk -F "=" '{print $2}'`
db_host=`cat ../../../config.ini | grep -w "^DB_HOST_REMOTE" | awk -F "=" '{print $2}'`
db_port=`cat ../../../config.ini | grep -w "^DB_PORT" | awk -F "=" '{print $2}'`
db_user=`cat ../../../config.ini | grep -w "^DB_USER" | awk -F "=" '{print $2}'`
db_password=`cat ../../../config.ini | grep -w "^DB_PASSWORD" | awk -F "=" '{print $2}'`
db_schema=`cat ../../../config.ini | grep -w "^DB_SCHEMA" | awk -F "=" '{print $2}'`

platform=$2
#printf "$1, $2\n"|tee -a ${git_dir}/code_resource/script_hooks/scan_apk/apk_info_scan/apk_scan_history.log

#${git_dir}/code_resource/script_hooks/scan_apk/apk_info_scan/bb_protection_scan.sh $1 $2
#${git_dir}/code_resource/script_hooks/scan_apk/apk_info_scan/3rd_party_lib_scan.sh $1 $2
#${git_dir}/code_resource/script_hooks/scan_apk/apk_info_scan/x86_lib_missing.sh $1 $2
${git_dir}/code_resource/script_hooks/scan_apk/apk_info_scan/all_check.sh $1 

apk_namel=$1
apk_info=`cat temp_file`
apk_name=${apk_namel##*/}
mysql -h${db_host} -P${db_port}  -u${db_user} -p${db_password} ${db_schema} -e "update apk set lib_info_desc = '$apk_info' where pkg_name = '$apk_name' and app_platform='$platform'"


