#!/bin/bash

rm allapp.txt templist templist2

ls *.csv | while read oneline
do
	cat $oneline | awk -F "," '{print $11}' >> templist
done

cat templist | sort | uniq > templist2
sed -e 's/$/\r/' templist2 > allapp.txt
