#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2

bb_so_dir=$apk_uzipped_folder/assets

#check if some rules matched, then log the APK name
if ls -R |grep -E '(libsecexe.so|libsecmain.so|libsecexe.x86.so|libsecmain.x86.so)' ; then
    printf "梆梆加固 \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libnqshield.so|libnqshieldx86.so)' ; then
    printf "网秦安全盾 \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libexec.so|libexecmain.so)'; then
    printf "爱加密 \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libprotectClass.so|libprotectClass_x86.so)' ; then
    printf "360加固 \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libDexHelper.so|libDexHelper-x86.so)' ; then
    printf "梆梆加固(付费版) \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libchaosvmp.so)' ; then
    printf "娜迦加固 \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libCtxTFE.so)'; then
    printf "Citrix XenMobile \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(dexmaker.jar)'; then
    printf "DexMaker \n" |tee -a $apk_uzipped_folder/apk_info
fi
if ls -R |grep -E '(libmegjb.so)'; then
    printf "CMCC Billing SDK \n" |tee -a $apk_uzipped_folder/apk_info
fi
