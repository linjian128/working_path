#!/bin/bash

read_elf=eu-readelf
git_dir="/home/Git-Apk"

for apk in `ls ${git_dir}/All_Apk/*.apk`
do
    apk_name=`basename $apk`
    printf "$apk_name \n"
    if [ -f ${git_dir}/All_Apk/$apk_name ]; then
        unzip ${git_dir}/All_Apk/$apk_name -d ${git_dir}/.git/hooks/apk_info_scan/$apk_name 

        arm_folder=`find ${git_dir}/.git/hooks/apk_info_scan/$apk_name -iname "*arm*" -type d|gawk '{IGNORECASE = 1} /arm/ {print $1}'`
        x86_folder=`find ${git_dir}/.git/hooks/apk_info_scan/$apk_name -name "*86*" -type d|gawk '/86/ {print $1}'`
        intel_folder=`find ${git_dir}/.git/hooks/apk_info_scan/$apk_name -iname "*intel*" -type d|gawk '{IGNORECASE = 1} /intel/ {print $1}'`

        #printf "arm folder: $arm_folder\n"|tee -a count.log
        #printf "x86 folder: $x86_folder\n"|tee -a count.log
        #printf "intel folder: $intel_folder\n"|tee -a count.log

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

        #Only for ARM
        if [ $x86_so_num -eq 0 ] && [ $arm_so_num -gt 0 ]
        then
           printf "$apk_name is for ARM only\n"|tee -a miss.log 
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
        miss_x86_lib=0 
        if [ $arm_so_num -gt 0 ] && [ $x86_so_num -gt 0 ] && [ $arm_so_num -ne $x86_so_num ]
        then
           for so in `find $x86_folder -iname "*x86*" -type f|sed s/x86//i`
           do
               so_name=`basename $so`
               if [ ! -f $arm_folder/$so_name ]
               then
                   miss_x86_lib=1
               fi
           done
 
           for so in `find $x86_folder -iname "*intel*" -type f|gawk '{IGNORECASE = 1} /intel/ {print $0}'|sed s/froyo//i`
           do
               so_name=`basename $so`
               if [ ! -f $arm_folder/$so_name]
               then
                   miss_x86_lib=1
               fi
           done
           if [ -z "$so_name" ]
           then
               miss_x86_lib=1
           fi

           fi

           if [ $arm_so_num -gt 0 ] && [ $x86_so_num -gt 0 ] && [ $arm_so_num -eq $x86_so_num ]
            then
                miss_x86_lib=0
            fi
 
           if [ $miss_x86_lib -ne 0 ]
           then
               printf "$apk_name: missing x86 lib\n"|tee -a miss.log
           fi
    fi

    rm -rf ${git_dir}/.git/hooks/apk_info_scan/$apk_name
done

date

