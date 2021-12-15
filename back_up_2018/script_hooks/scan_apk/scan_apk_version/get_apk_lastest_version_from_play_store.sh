#!/bin/bash


#the first parameter is the directory cantians all apk
#the second parameter is the list of apk name that needed to process
APK_POOL_DIR=$1
APK_LIST=$2

WD=`pwd`
#WD="/srv/www/htdocs/CV2/app/admin/scan_apk_version/"
TOTAL=`cat ${APK_LIST} | wc -l`
START_TIME=`date +%Y-%m-%d-%H-%M-%S`
START=`date +%s`
LOGS_DIR=${WD}"/logs"
LOG_FILE=${LOGS_DIR}"/"${START_TIME}".log"

RESULT_DIR=${WD}"/results"
RESULT_FILE="AppInfo_"${START_TIME}".csv"

TEMP_RESULT_FILE=${WD}"/AppInfo.csv"
TEMP_CONTENT_FILE=${WD}"/content.tmp"

echo "Start processing app in list ${APK_LIST} from ${APK_POOL_DIR}  ......" >>  ${LOG_FILE}
echo ""  >>  ${LOG_FILE}
#echo ${START} >> ${LOG_FILE}

rm ${TEMP_RESULT_FILE}


echo "ApkName","LatestVersionOnGooglePlay" > ${TEMP_RESULT_FILE}


COUNT=1

while read APK_NAME
do
    echo "============================================================================" >>  ${LOG_FILE}
    echo "${COUNT}/${TOTAL} Starting processing ${APK_NAME} ......"  >>  ${LOG_FILE}
    APK_FILE=${APK_POOL_DIR}/${APK_NAME}
    echo "${APK_FILE}"

    aapt d badging ${APK_FILE} > /dev/null

    if [ $? != 0 ]
    then
        echo "Error ouccus when processing ${APK_NAME} : Cnnot get apk info by aapt !" >> ${LOG_FILE}
        continue
    else
        PACK_NAME=`aapt d badging ${APK_FILE} | grep "package: name=" | awk -F "'" '{print $2}'`
        VERSION=`aapt d badging ${APK_FILE} | grep "versionName=" | awk -F "'" '{print $(NF-1)}'`

        if [ "${PACK_NAME}-1.apk" != "${APK_NAME}" ]
        then
            echo "[WARNING] : Name Dismatch!!! ${APK_NAME} ==>  ${PACK_NAME}"  >> ${LOG_FILE}
        fi
        #echo "${PACK_NAME} : ${VERSION}"

        URL="https://play.google.com/store/apps/details?id=${PACK_NAME}"

        echo "Getting apk info from ${URL} ......" >> ${LOG_FILE}
        #curl --socks5-hostname proxy.jf.intel.com:1080 ${URL} -o ${TEMP_CONTENT_FILE}
        curl --proxy https://child-prc.intel.com:913 ${URL} -o ${TEMP_CONTENT_FILE}
        grep -q "We're sorry, the requested URL was not found on this server." ${TEMP_CONTENT_FILE}
        if [ $? -eq 0 ]
        then
            echo "[ERROR] : Cannot find info of ${APK_NAME} on ${URL} !!!"  >> ${LOG_FILE}
            LASTVERSION="N/A"
        else
            echo "Success to get info from Play Store"  >> ${LOG_FILE}
            LASTVERSION=`cat ${TEMP_CONTENT_FILE} | awk -F '"softwareVersion">' '{print $2}' | awk -F "<" '{print $1}' | sed '/^$/d'`
            echo "The lastest version of ${APK_NAME} is ${LASTVERSION}" >> ${LOG_FILE}
        fi

        echo "${APK_NAME}","${LASTVERSION}" >> ${TEMP_RESULT_FILE}
 
    fi


    echo "Done processing ${APK_NAME}"  >> ${LOG_FILE}

    let COUNT=${COUNT}+1
    END=`date +%s`
    TIME=$((END-START))
    DAY=$(($(($TIME/(3600*24)))))
    HOUR=$(($(($TIME%(3600*24)))/3600))
    MINUTE=$(($(($TIME%3600))/60))
    SECOND=$(($(($TIME%3600))%60))
    echo "Time Spent:   $DAY Days $HOUR Hours $MINUTE Minutes $SECOND Seconds" >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    
done < ${APK_LIST}

echo "============================================================================" >>  ${LOG_FILE}

cp ${TEMP_RESULT_FILE} ${RESULT_DIR}/${RESULT_FILE}
rm -rf ${TEMP_CONTENT_FILE}

echo "" >>  ${LOG_FILE}
echo "" >>  ${LOG_FILE}
echo "**************************************************************" >>  ${LOG_FILE}
echo "All Done" >>  ${LOG_FILE}
echo "Total Time:   $DAY Days $HOUR Hours $MINUTE Minutes $SECOND Seconds" >>  ${LOG_FILE}
echo "Result Location:               ${RESULT_DIR}/${RESULT_FILE}" >>  ${LOG_FILE}
echo "**************************************************************" >>  ${LOG_FILE}

