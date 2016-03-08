#!/bin/bash
#set -x
if [[ $# -ne 2 ]]
then 
	echo "usage: ./xx.sh LIB_DIR TOOLS_DIR"
	echo "exiting....."
	exit
fi

## Input directory can be relative or absolute, may or may not end with '/'
cd $1
LIBS=$PWD
cd - > /dev/null

TOOLS_DIR=$2

## api list directory for each exsiting NON-NDK libraries
APIS=./LIB_func
rm -rf $APIS
mkdir -p $APIS

declare -i count
count=0
for libd in `ls $LIBS/*.so`
do
	libn=`basename $libd`
	## key word ".text" may not be strong enough
	$TOOLS_DIR-objdump -T $libd | grep -F ".text" > $APIS/$libn.func	
	count=$count+1
done

echo "totally dump $count non-ndk libraries"

exit
