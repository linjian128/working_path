#!/bin/bash
#set -x

ARMABI="armeabi"
ARMV7ABI="armeabi-v7a"
ARM64ABI="arm64-v8a"
X86ABI="x86"
X8664ABI="x86_64"
thirdpartylist="ThirdPartySO"

unzip_tmp="unzip_temp"

# Use armRef as a reference, compare all libraries of iaRef with all
# libraries of armRef. If both are match, global variable 'retAbiName' 
# will be iaRef and true(0) is return value, Or else, 'retAbiName'
# will be set as armRef and false(1) will be returned.
#
# And if both armRef iaRef is empty, 'retAbiName' will be rawResult
compare(){
	local armRef=$1
	local iaRef=$2
	local rawResult=$3
	local apk="$4"

	retAbiName=$rawResult

	if [ "$iaRef" == "X" ]; then
		if [ "$armRef"  != "X"  ];then
			retAbiName=$armRef
			return 1
		else
			retAbiName=$rawResult
                        return 0
		fi
	fi

	# if has reliable lib, return iaRef 
	if isReliableLib $iaRef "$apk"; then
		retAbiName=$iaRef	
		return 0
	fi	

	#compare 3rd lib
		for libPath in `aapt l "$apk"|grep ^lib|grep "/$armRef/"`
		do
			armlibname=${libPath#*lib/$armRef/}	
			if is3rdlib $armlibname && ! aapt l "$apk"|grep ^lib|grep "/$iaRef/"|cut -d/ -f3|grep "$armlibname" >/dev/null; then
				err_msg="$err_msg, \033[32mMissing 3rd lib '$armlibname' in lib/$iaRef/\033[0m"
				retAbiName=$armRef
				return 1
			fi
		done

	#compare user lib
	iauserlibCount=`getuserlibCount $iaRef "$apk"`
	armuserlibCount=`getuserlibCount $armRef "$apk"`
	if [ $armuserlibCount -gt 0 ] && [ $iauserlibCount -eq 0 ];then
		err_msg=", \033[31mMissing user lib\033[0m"
		retAbiName=$armRef
		return 1
	fi
		
	retAbiName=$iaRef
	return 0
}


isReliableLib(){
	local ABI=$1
	local apk="$2"

	if aapt l "$apk"|grep "^lib"|grep "/$ABI/"|cut -d/ -f3|grep -E "(intel|atom|x86|x64)" >/dev/null ; then
		err_msg=", \033[33mapk has reliable lib\033[0m"
		return 0
	else
		return 1
	fi
}

getuserlibCount(){
	local Ref=$1
	local apk="$2"

	userlibCount=0
	#usrlibCount=`aapt l "$apk"|grep ^lib|grep "/$Ref/"|cut -d/ -f3|grep $3rdlist`
	for libPath in `aapt l "$apk"|grep ^lib|grep "/$Ref/"`
        do
                libname=${libPath#*lib/$Ref/}
		if ! is3rdlib $libname; then 
			let userlibCount+=1
		fi
	done 
	
	echo $userlibCount
}


is3rdlib(){
	
	if grep "$1" $thirdpartylist >/dev/null
	then	
		return 0
	else
		return 1
	fi
}

getSpecficABILibCount(){
	local ABI=$1
	local apk="$2"
	aapt l "$apk" |grep ^lib.*.so|cut -d/ -f2|grep "$ABI"|wc -l 
}


pickupRightABI(){
	local apk="$1"
	local sysPreferAbiName=$2

	armv7LibCount=`getSpecficABILibCount $ARMV7ABI "$apk"`
	armv5LibCount=`getSpecficABILibCount $ARMABI "$apk"`
	armv8LibCount=`getSpecficABILibCount $ARM64ABI "$apk"`
	x86LibCount=`getSpecficABILibCount $X86ABI "$apk"`
	x8664LibCount=`getSpecficABILibCount $X8664ABI "$apk"`


	if [ $x8664LibCount -gt 0 ]; then  ia64Ref=$X8664ABI; else ia64Ref="X"; fi;
	if [ $armv8LibCount -gt 0 ]; then  arm64Ref=$ARM64ABI; else arm64Ref="X"; fi;
	if [ $x86LibCount -gt 0 ]; then  ia32Ref=$X86ABI; else ia32Ref="X"; fi;
	if [ $armv7LibCount -gt 0 ]; then  arm32Ref=$ARMV7ABI; elif [ $armv5LibCount -gt 0 ]; then arm32Ref=$ARMABI; else arm32Ref="X"; fi;

	if hasmixedarmlib "$apk" $X86ABI; then ia32Ref="X" x86LibCount=0; fi;
	if hasmixedarmlib "$apk" $X8664ABI; then ia64Ref="X" x8664LibCount=0; fi;



	#echo "--"	
	#echo "$apk, armv8LibCount=$armv8LibCount, armv5LibCount=$armv5LibCount, rmv7LibCount=$armv7LibCount, x86LibCount=$x86LibCount, x8664LibCount=$x8664LibCount"
	#aapt d badging "$apk" |grep native-code
	#echo "--"	

	if [ $sysPreferAbi == $X8664ABI ] && [ $x8664LibCount -gt 0 ]; then
		if ! compare $arm64Ref $ia64Ref $sysPreferAbiName "$apk"; then
			sysPreferAbiName=$retAbiName
			compare $arm32Ref $ia32Ref $sysPreferAbiName "$apk"
		fi
	else
		compare $arm32Ref $ia32Ref $sysPreferAbiName "$apk"
	fi

}

# $1: apk file
hasmixedarmlib(){
        local apk="$1"
        local iaRef=$2
	
	if aapt l "$apk" |grep  "/$iaRef/" >/dev/null; then
		rm -rf $unzip_tmp

		if ! unzip "$apk" -d $unzip_tmp >/dev/null; then
			echo  "Failed to unzip $apk "
		else
			#echo Scaning [$iaRef] $1 ...
			for line in `find $unzip_tmp/lib/$iaRef -name "*.so"`
			do
				if readelf -h $line |grep Machine |grep ARM > /dev/null; then
					mixed_lib_msg="$mixed_lib_msg \033[33m Mixed lib: ${line#*lib/} \033[0m" 
					return 0
				fi
			done
		fi
	fi
	
	return 1
}


pick_sysPreferAbi() {
    echo "Please choose prefer ABI: "
    echo "- 1. $X86ABI		       "
    echo "- 2. $X8664ABI               "
    echo "- 0.exit                     "
    echo " "

    read select_option

    case $select_option in
            1)
                        sysPreferAbi=$X86ABI;;
            2)
                        sysPreferAbi=$X8664ABI;;
            0) exit 0;;
            *) echo "Input error!";exit 1;;
    esac
}

isx86app(){
	local apk="$1"

	if aapt l "$apk" |grep ^lib|cut -d/ -f2|grep -i x86 > /dev/null; then
		return 0
	else 
		return 1
	fi
}

if ! file $thirdpartylist >/dev/null; then
         echo -e "\033[31m Please check madontory files! \033[0m" 
         exit 0
fi


app_no=`ls *.apk |wc -l`
no=0

pick_sysPreferAbi

# $1 is system Prefer AbiName
# retAbiName is the final ABI, global variable 
for apk in *.apk
do 
	err_msg=""
	mixed_lib_msg=""
	armv7LibCount=`getSpecficABILibCount $ARMV7ABI "$apk"`
	armv5LibCount=`getSpecficABILibCount $ARMABI "$apk"`
	armv8LibCount=`getSpecficABILibCount $ARM64ABI "$apk"`

	ndk=`aapt d badging "$apk" |grep native-code|cut -d: -f2`

	if isx86app "$apk"; then
		pickupRightABI "$apk" $sysPreferAbi 
		if [ "X$mixed_lib_msg" != "X" ]; then mixed_lib_msg=", $mixed_lib_msg"; fi;
		echo -e "($no/$app_no)\033[31m[$retAbiName]\033[0m, $apk, $ndk $err_msg $mixed_lib_msg"
		let no+=1
		continue
	elif [ $armv7LibCount -gt 0 ];then 
		retAbiName=$ARMV7ABI
	elif [ $armv5LibCount -gt 0 ];then
		retAbiName=$ARMABI
	elif [ $armv8LibCount -gt 0 ];then
		retAbiName=$ARM64ABI 
	else
		retAbiName="None"
	fi

	echo -e "($no/$app_no)\033[32m[$retAbiName]\033[0m, $apk, $ndk $err_msg $mixed_lib_msg"

	let no+=1
done
