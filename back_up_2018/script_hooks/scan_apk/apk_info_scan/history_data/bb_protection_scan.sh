#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2

bb_so_dir=$apk_uzipped_folder/assets

#check if some rules matched, then log the APK name
if [ -e "$bb_so_dir/libsecexe.x86.so" ]||[ -e "$bb_so_dir/libsecmain.x86.so" ]; then
    printf "Bangbang Protected: Yes \n" |tee -a $apk_uzipped_folder/apk_info
else
    printf "Bangbang Protected: No \n" |tee -a $apk_uzipped_folder/apk_info
fi

if [ -e "$bb_so_dir/libnqshieldx86.so" ]; then
    printf "NQ Shield Protected: Yes \n" |tee -a $apk_uzipped_folder/apk_info
else
    printf "NQ Shield Protected: No \n" |tee -a $apk_uzipped_folder/apk_info
fi

if [ -e "$bb_so_dir/libmegbpp_02.02.01_01.so" ]; then
    printf "Contain libmegbpp_02.02.01_01.so: Yes \n" |tee -a $apk_uzipped_folder/apk_info
fi

check_3rd_lib $APK "libsecexe.so|libsecmain.so|libsecexe.x86.so|libsecmain.x86.so"      梆梆加固
check_3rd_lib $APK "libnqshield.so|libnqshieldx86.so"   网秦安全盾
check_3rd_lib $APK "libexec.so|libexecmain.so"  爱加密
check_3rd_lib $APK "libprotectClass.so|libprotectClass_x86.so"  360加固
check_3rd_lib $APK "libDexHelper.so|libDexHelper-x86.so"        "梆梆加固(付费版)"
check_3rd_lib $APK "libchaosvmp.so"     娜迦加固
check_3rd_lib $APK "libCtxTFE.so"       "Citrix XenMobile"
check_3rd_lib $APK "dexmaker.jar"       DexMaker

