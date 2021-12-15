#!/usr/bin/env bash

git_dir=`cat ../../../config.ini | grep -w "^GIT_LOCAL_URL" | awk -F "=" '{print $2}'`
db_host=`cat ../../../config.ini | grep -w "^DB_HOST_REMOTE" | awk -F "=" '{print $2}'`
db_port=`cat ../../../config.ini | grep -w "^DB_PORT" | awk -F "=" '{print $2}'`
db_user=`cat ../../../config.ini | grep -w "^DB_USER" | awk -F "=" '{print $2}'`
db_password=`cat ../../../config.ini | grep -w "^DB_PASSWORD" | awk -F "=" '{print $2}'`
db_schema=`cat ../../../config.ini | grep -w "^DB_SCHEMA" | awk -F "=" '{print $2}'`
platform=$1

for apk in `cat Updated_list`
do

    if [ -f ${git_dir}/$platform/$apk ]; then
        pushd ./../apk_info_scan/ >/dev/null
        ./apk_info_scan.sh ${git_dir}/$platform/$apk $platform
        popd >/dev/null

        unzip ${git_dir}/$platform/$apk -d ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/$apk > ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/log
        cd ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/$apk
        for libname in `find . -name "*.so"`
        do
            asm_file=${libname//.so/.asm}
            ./../objdump -d $libname > $asm_file
        done
        cd ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/
        python scan_neon.py ${db_host} ${db_user} ${db_password} ${db_schema}
        rm -rf $apk
        modi_date=`stat ${git_dir}/$platform/$apk | grep Modify | awk '{print $2}'`
        mysql -h${db_host} -P${db_port}  -u${db_user} -p${db_password} ${db_schema} -e "update apk set update_date = '$modi_date' where pkg_name = '$apk' and app_platform='$platform'"
        echo $modi_date >> ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/sql.sql
        echo "update apk set update_date = '$modi_date' where pkg_name = '$apk' and app_platform='$platform'" >> ${git_dir}/code_resource/script_hooks/scan_apk/neon_scan/sql.sql
    fi
done

rm -rf Updated_list
