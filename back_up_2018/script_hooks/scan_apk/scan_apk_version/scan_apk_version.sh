#!/bin/bash

#the first parameter is the directory cantians all apk
#the second parameter is the list of apk name that needed to process
APK_POOL_DIR=$1
APK_LIST=$2

echo "$APK_POOL_DIR"
echo "$APK_LIST"

./get_apk_lastest_version_from_play_store.sh $APK_POOL_DIR $APK_LIST > /dev/null

php update_apk_lastest_version.php
