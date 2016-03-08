#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2


arm_folder=`find $apk_uzipped_folder -name "*armeabi-v7a" -type d|gawk '{IGNORECASE = 1} /arm/ {print $1}'`
x86_folder=`find $apk_uzipped_folder -name "*/x86" -type d|gawk '/86/ {print $1}'`

arm_so_num=0
x86_so_num=0
if [ -n "$arm_folder" ]
then
  arm_so_num=`ls $arm_folder/*.so -l|grep "^-" |wc -l|gawk '// {print}'`
fi

if [ -n "$x86_folder" ]
then
  x86_so_num=`ls $x86_folder/*.so -l|grep "^-" |wc -l|gawk '// {print}'`
fi

miss_x86_lib=0
if [ $arm_so_num -gt 0 ] && [ $x86_so_num -gt 0 ] && [ $arm_so_num -ne $x86_so_num ]
then
   miss_x86_lib=1
fi

#printf "apk_uzipped_folder: $apk_uzipped_folder \n"
if [ $miss_x86_lib -ne 0 ]
then
  printf "X86 lib Missing: Yes \n"|tee -a $apk_uzipped_folder/apk_info
fi

