#!/bin/sh

#set -x
#python parse.py

for log_n in `cat number`
do
	file="${log_n}"
	mm=`echo $1|cut -d/ -f1`
	dd=`echo $1|cut -d/ -f2`
	yy=`echo $1|cut -d/ -f3`
	output="${log_n}_${mm}${dd}.txt"
	sed -n '/'"$mm"'\/'"$dd"'\/'"$yy"'/,$p' $file > $output #|grep -E "$(date)|callid"  grep -E '.*/.*/2015'
done
