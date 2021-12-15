#!/bin/bash

#get input
apk_name=$1
apk_uzipped_folder=$2


arm_folder=`find $apk_uzipped_folder -iname "*arm*" -type d|gawk '{IGNORECASE = 1} /arm/ {print $1}'`
x86_folder=`find $apk_uzipped_folder -name "*86*" -type d|gawk '/86/ {print $1}'`
intel_folder=`find $apk_uzipped_folder -iname "*intel*" -type d|gawk '{IGNORECASE = 1} /intel/ {print $1}'`

arm_so_num=0
x86_so_num=0
intel_so_num=0
if [ -n "$arm_folder" ]
then
  arm_so_num=`ls $arm_folder/*.so -l|grep "^-" |wc -l|gawk '// {print}'`
fi

if [ -n "$x86_folder" ]
then
  x86_so_num=`ls $x86_folder/*.so -l|grep "^-" |wc -l|gawk '// {print}'`
fi

if [ -n "$intel_folder" ]
then
  intel_so_num=`ls $intel_folder/*.so -l|grep "^-" |wc -l|gawk '// {print}'`
fi

miss_x86_lib=0
#Only for ARM
if [ $x86_so_num -eq 0 ] && [ $arm_so_num -gt 0 ]
then
    printf "$apk_name is for ARM only\n"
fi

#Only for X86
if [ $arm_so_num -eq 0 ] && [ $x86_so_num -gt 0 ]
then
    printf "$apk_name is for X86 only\n"
fi

#Pure JAVA
if [ $arm_so_num -eq 0 ] && [ $x86_so_num -eq 0 ]
then
    printf "No ARM/X86 lib, pure JAVA\n"
fi

#ARM/X86 Mixing
if [ $arm_so_num -gt 0 ] && [ $x86_so_num -gt 0 ] && [ $arm_so_num -ne $x86_so_num ]
then
  iss_x86_lib=1
   printf "No ARM/X86 lib, pure JAVA\n"
fi

if [ $miss_x86_lib -ne 0 ]
then
  printf "X86 lib Missing: Yes \n"|tee -a $apk_uzipped_folder/apk_info
else
  printf "X86 lib Missing: No \n"|tee -a $apk_uzipped_folder/apk_info
fi

