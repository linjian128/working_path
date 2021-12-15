#!/bin/bash
#set -x
app=${1}
platform=${2}

db_host=`cat ../../../config.ini | grep -w "^DB_HOST_REMOTE" | awk -F "=" '{print $2}'`
#db_host='hades-vb.sh.intel.com'
db_user=`cat ../../../config.ini | grep -w "^DB_USER" | awk -F "=" '{print $2}'`
db_password=`cat ../../../config.ini | grep -w "^DB_PASSWORD" | awk -F "=" '{print $2}'`
db_schema=`cat ../../../config.ini | grep -w "^DB_SCHEMA" | awk -F "=" '{print $2}'`

if [[ ! -f ${app} ]]; then
    return
fi
packageName=`aapt d badging ${app}|grep "package: name"|awk -F "'" '{print $2}'`

function scan() {
    app=${1}
    value=''

    if [[ ! -f ${app} ]]; then
        return
    fi
    
    aapt l "${app}" |grep -i "libsecuritysdk" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        value=`aapt l "${app}" | grep -i "libsecuritysdk" | awk -F "/" '{print $NF}'`
    fi

    if [[ ${value} != '' ]]; then
        updateData ${value}
    else
        scanPlugin ${app}
    fi
}

function updateData() {
    libInfo=${1}
    libInfos=`mysql -N -u${db_user} -p${db_password} -h${db_host} ${db_schema} -e "select lib_info_desc from apk where cv_name='${packageName}' and app_platform='${platform}';"`
    
    if [[ "${libInfos[0]}" == '' || ${libInfos[0]} == NULL ]]; then
        mysql -u${db_user} -p${db_password} -h${db_host} ${db_schema} -e "update apk set lib_info_desc='${libInfo}' where cv_name='${packageName}' and app_platform='${platform}';"
        return
    fi

    echo ${libInfos[0]} | grep -q -w "${libInfo}"
    if [[ $? -ne 0 ]]; then
        echo ${libInfos[0]} | grep -q -w "libsecuritysdk"
        if [[ $? -eq 0 ]]; then
            oldLibSecurityInfo=`echo ${libInfos[0]}|grep -i -o "libsecuritysdk.*"`
            newLibInfo=`echo ${libInfos[0]}|grep -i "libsecuritysdk"|sed "s/${oldLibSecurityInfo}/${libInfo}/g"`
            mysql -u${db_user} -p${db_password} -h${db_host} ${db_schema} -e "update apk set lib_info_desc='${newLibInfo}' where cv_name='${packageName}' and app_platform='${platform}';"
            return
        fi
        mysql -u${db_user} -p${db_password} -h${db_host} ${db_schema} -e "update apk set lib_info_desc=concat(lib_info_desc, ',${libInfo}') where cv_name='${packageName}' and app_platform='${platform}';"
    fi
}

function scanPlugin() {
    app=$1
    aapt l -a "${app}" |grep ".apk$" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        rm -rf "${app}_unzip"
        unzip -qq "${app}" -d "${app}_unzip"

        for item in `find ${app}_unzip -name "*.apk"`
        do
            scan "${item}"
        done
        rm -rf "${app}_unzip"
    fi
}

scan ${app}
