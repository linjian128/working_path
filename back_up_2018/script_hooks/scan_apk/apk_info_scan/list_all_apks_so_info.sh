#!/bin/bash

git_dir="/home/Git-Apk"
counter=0
output_file="list_all_apks_so_info.txt"

if [ -f $output_file ]; then
    rm $output_file
fi

touch $output_file

for apk in $(ls $git_dir/All_Apk/*.apk); do
    apk_name=$(basename $apk)

    echo "$apk_name" | tee -a $output_file

    unzip -l $apk | grep "\.so$" | tee -a $output_file

#    counter=$((counter+1))
#    if [ $counter -ge 10 ]; then
#        break
#    fi
done
