#!/bin/bash

total=`ls | grep .apk | wc -l`
no=1
for path in `ls | grep .apk`
do
    cd $path
    echo "$path $no/$total"
    for libname in `find . -name "*.so"`
    do
        asm_file=${libname//.so/.asm}
        ./../objdump -d $libname > $asm_file
    done
    cd ..
    let no=no+1
done
