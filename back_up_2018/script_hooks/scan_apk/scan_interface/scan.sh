## Author: Wanhailong Date: May.12, 2014
#!/bin/bash
#set -x
if [ $# -ne 2 ]
then
	echo "Usage:  ./scan.sh ./LIB_DIR ./APK_DIR" 
        echo -e "\tfor example ./scan.sh ./LIB ./APK"
        echo -e "\t\t or ./scan.sh ./LIB admin@host:~/APK"
	echo -e "\t\t or ./scan.sh ./LIB @    # use default remote directory"
	exit 1
fi

## Need all the listed non-ndk lib files, they are pulled from a target device into LIB_DIR according to a list

## APK_DIR can be local or remote, if it's remote, need to have server's rsa key authorization already implement

if [ -d ./LOG ]; then
rm -rf ./LOG
fi

mkdir LOG

SCRIPTS_DIR=./scripts

## Set toolchain dir and prefix
TOOLS_DIR=./tool/arm-none-linux-gnueabi

## Dump non-ndk libraries to get symbol table (the api user lib may call)
## Generate file in $APIS=./LIB_func
$SCRIPTS_DIR/gen_api_list.sh $1 $TOOLS_DIR

## Unpack all application apks from APK_DIR, then perform readelf and objdump on ARM native user lib 
# Generate file in $UNPAPKS=./APK_unpack
$SCRIPTS_DIR/gen_userlib_info.sh $2 $TOOLS_DIR

# test
#echo "0021e8e0 g    DF *UND*	000001b0 _Z18dvmOptimizeDexFileillPKcjjb" >> ./APK_objdump/com.square_enix.chaosringsomega.googleplay-1.apk/libmc_eruption_for_android_jni.so.dump

## Scan elf and dump infromation to generate call list
## Generate file in ./report
$SCRIPTS_DIR/gen_call_list.sh ./APK_readelf ./APK_objdump ./LIB_func 

rm -rf ./APK_unpack
rm -rf ./APK_readelf
rm -rf ./APK_objdump
rm -rf ./LIB_func

## Note! unpack_apk.sh and read_user_lib.sh will be integrated into one piece, because we need to unpack->read->delete for large scale scan
