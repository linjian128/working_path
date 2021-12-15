#!/bin/bash
#set -x

third_lib_list="ThirdPartySO"
unzip_tmp="temp_unzip"
temp_file="temp_file"
support_list="support_list"
supported_bangbang_md5="bm.check.list"
supported_360v2_md5="jm.check.list"
Fail_List="fail_list"

apk=$1

unzip_apk(){
	rm -rf $unzip_tmp
     	if ! unzip "$1" -d $unzip_tmp >/dev/null; then
		echo  "Failed to unzip $1 " >> $Fail_List
		return 1
	else 	
		return 0
	fi
}


check_3rd_lib(){
		contain_3rd_lib=0
		if aapt l "$1" |grep -E $2 >/dev/null; then
			contain_3rd_lib=1
		fi
		if [ $contain_3rd_lib -ne 0 ]; then
			echo -e "\033[32m$1,$3 \033[0m"
			echo "$3 " >> $temp_file
		fi

}
check_bangbang_support(){
        if aapt l "$1" |grep -E "libsecexe.so|libsecmain.so|libsecexe.x86.so|libsecmain.x86.so|libsecpreload.x86.so|libsecpreload.so" >/dev/null; then
                if unzip_apk "$1"; then
			if ! find $unzip_tmp -name libsecexe.so|xargs -i md5sum {} |awk '{print $1}'|sort|uniq |xargs -i grep {} $supported_bangbang_md5 > /dev/null; then
				echo $1,梆梆加固, unsupported >> $support_list
			else
				echo $1,梆梆加固, supported >> $support_list
			fi
		fi
	fi
}

#check_3rd_lib "$apk" "libjiagu_art.so|libjiagu.so"  360加固_V2
check_360V2(){
	f_360v2="No"
	if aapt l "$1" |grep -E "libjiagu_art.so|libjiagu.so" >/dev/null; then
                echo -e "\033[32m$1, 360加固_V2  \033[0m"
                echo "360加固_V2" >> $temp_file        
                f_360v2="Yes"
        fi
	
	if [ $f_360v2 == "Yes" ] ; then
		if [ "x${Missing_X86}" == "xNo" ]; then 
			if unzip_apk "$1"; then
				if ! find $unzip_tmp -name "libjiagu.so"|xargs -i md5sum {} |awk '{print $1}'|sort|uniq|xargs -i grep {} $supported_360v2_md5 > /dev/null; then
					echo $1,360加固_V2, unsupported >> $support_list
					return 0
				fi
			fi
		fi
		echo $1,360加固_V2, supported >> $support_list
	fi
}


check_cmcc(){
	CMCC="No"
        if aapt l "$1" |grep -E "libmegjb.so|libmegbpp" >/dev/null; then
                echo -e "\033[32m$1, CMCC Billing SDK  \033[0m"
                echo "CMCC Billing SDK" >> $temp_file	
		CMCC="Yes"
        fi
	
	if [ $CMCC == "Yes" ]; then
		if aapt l "$1" |grep "libmegbpp" >/dev/null; then
			cmcc_lib=`aapt l "$1" |grep "libmegbpp"`
			lib_name=`echo $cmcc_lib|awk -F'/' '{print $NF}'`
			#echo -e "\033[32m$1, CMCC($lib_name)  \033[0m"
			#echo "$1,CMCC($lib_name)" >> $temp_file

			lib_ver=`echo $lib_name |cut -d. -f3|cut -d_ -f1`
			if [ $lib_ver -gt 11 ]; then 
				echo $1,CMCC, unsupported >> $support_list
				return 0 
			fi
		fi
		echo $1,CMCC, supported >> $support_list
	fi
}

check_tencent_protection(){
	if aapt l "$1" |grep "libshell.so" >/dev/null && aapt l "$1" |grep "libmain.so" >/dev/null; then
        	echo -e "\033[32m$1, 腾讯加固  \033[0m"
		echo "腾讯加固" >> $temp_file
        fi
}

check_aijiami_protection(){
	if aapt l "$1" |grep "libexec.so" >/dev/null && aapt l "$1" |grep "libexecmain.so" >/dev/null; then
        	echo -e "\033[32m$1, 爱加密  \033[0m"
		echo "爱加密" >> $temp_file
        fi
}

check_bangbang_protection(){
	if (aapt l "$1" |grep "libsecexe.so" >/dev/null && aapt l "$1" |grep "libsecmain.so" >/dev/null)||(aapt l "$1" |grep "libsecexe.x86.so" >/dev/null && aapt l "$1" |grep "libsecmain.x86.so" >/dev/null) ||(aapt l "$1" |grep -E "libsecpreload.x86.so|libsecpreload.so" >/dev/null) ; then
                echo -e "\033[32m$1, 梆梆加固 \033[0m"
                echo "梆梆加固" >> $temp_file
        fi

}
check_ali_protection(){
	if (aapt l "$1" |grep "libmobisec.so" >/dev/null && aapt l "$1" |grep "libmobisecy1.so" >/dev/null && aapt l "$1" |grep "libmobisecz1.so" >/dev/null); then
		echo -e "\033[32m$1, Ali  \033[0m"
                echo "Ali Protection" >> $temp_file
	fi
}

x86_missing_check() {
	Missing_X86=""
	#apk both contains lib/x86 & lib/arm* libs need to be checked
	if aapt l "$1"|grep '^lib/x86/*'>/dev/null && aapt l "$1"|grep '^lib/armeabi*/*'>/dev/null; then  
		Missing_X86="No"
		#if contain v7 folder, scan v7, else scan v5
		if aapt l "$1" |grep '^lib/armeabi-v7a/*' >/dev/null; then 
			need_to_check_user_lib="Yes"
			missing_user_lib="No"
			
			for line in `aapt l "$1" |grep '^lib/armeabi-v7a/*'`
			do
				v7_lib_tmp=${line#*lib/armeabi-v7a/lib}
				v7_lib=${v7_lib_tmp%%.so*}
				if [ "X${v7_lib}" == "X" ]
				then
					continue
				fi
				#If this v7 lib is 3rd lib, need a same name lib under x86/ folder, or it would be missing x86 app
				if grep -i $v7_lib  $third_lib_list >/dev/null; then
					if ! aapt l "$1" |grep '^lib/x86/*'|grep $v7_lib >/dev/null; then 
						echo -e "\033[36m$1, X86 missing 3rd lib $v7_lib \033[0m"
						echo "X86 missing 3rd lib $v7_lib" >> $temp_file
						Missing_X86="Yes"
						break
					fi
				# user lib
				else 
					if [ $need_to_check_user_lib == "Yes" ]; then
						missing_user_lib="Yes"
						if aapt l "$1" |grep '^lib/x86/*'|grep $v7_lib >/dev/null; then
							missing_user_lib="No"
							need_to_check_user_lib="No"
							continue
						fi
					fi
				fi
			done 
			
			if [ $missing_user_lib == "Yes" ]; then
				echo -e "\033[36m$1, X86 missing user lib in lib/armeabi-v7a/ \033[0m"
				echo "X86 missing user lib in lib/armeabi-v7a/" >> $temp_file
				Missing_X86="Yes"
			#else
			#	echo $1, "not a missing x86 app"
			fi

		elif aapt l "$1" |grep '^lib/armeabi/*' >/dev/null; then
			need_to_check_user_lib="Yes"
			missing_user_lib="No"
			
			aapt l "$1" |grep '^lib/armeabi/*' | while read line
				do
					v5_lib_tmp=${line#*lib/armeabi/}
					v5_lib=${v5_lib_tmp%%.so*}
					if [ "X${v5_lib}" == "X" ]
					then
						continue
					fi
					need_to_check_user_lib="Yes"
					#If this v5 lib is 3rd lib, need a same name lib under x86/ folder, or it would be missing x86 app
					if grep -i $v5_lib  $third_lib_list > /dev/null; then
						if ! aapt l "$1" |grep '^lib/x86/*'|grep $v5_lib >/dev/null; then
							echo -e "\033[36m$1, X86 missing 3rd lib $v5_lib \033[0m"
							echo "X86 missing 3rd lib $v5_lib" >> $temp_file
							Missing_X86="Yes"
						break
						fi
					# user lib
					else
						if [[ $need_to_check_user_lib -eq "Yes" ]]; then
							missing_user_lib="Yes"
							if aapt l "$1" |grep '^lib/x86/*'|grep $v5_lib >/dev/null; then
								missing_user_lib="No"
								need_to_check_user_lib="No"
								break
							else
								continue
							fi
						fi
					fi
				done
				if [[ $missing_user_lib == "Yes" ]]; then
					echo -e "\033[36m$1, X86 missing user lib lib/armeabi/ $v5_lib \033[0m"
					echo "X86 missing user lib lib/armeabi/" >> $temp_file
					Missing_X86="Yes"
				#else
				#	echo $1, "not a missing x86 app"
				fi
		fi
	fi
}

mixed_javaArm_check(){
	#No need to check mixed and javaarm for ARM only apps
	if aapt d badging "$1" |grep native-code|grep -i "x86" >/dev/null || ! aapt d badging "$1"|grep native-code >/dev/null; then

      		rm -rf $unzip_tmp
		if ! unzip "$1" -d $unzip_tmp >/dev/null; then
			echo  "Failed to unzip $1 " >> $Fail_List
		else
			pushd $unzip_tmp >/dev/null
			#echo Scaning $1 ...
			find . -name "*.so"|grep '/lib/x86*' | while read line 
			do
				if readelf -h $line |grep Machine |grep ARM > /dev/null; then
					echo -e "\033[33m$1, Mixed app \033[0m"
					echo "Mixed app" >> ../$temp_file
					break
				fi
			done

			#if ! ( find . -name "*.so"|grep '/lib/arm'>/dev/null && ! find . -name "*.so"|grep '/lib/x86*' >/dev/null); then
			# scan purejava app
			if ! aapt d badging ../"$1" |grep native-code >/dev/null; then
				if [ -d "assets/" ]; then
					find assets/ -name "*"|xargs -i file {}|grep -i "elf"|cut -d: -f1 | while read line
					do
						if readelf -h $line |grep Machine |grep ARM >/dev/null; then
							echo -e "\033[31m$1, PureJava app contains at least one arm lib: $line \033[0m"
							echo "PureJava app contains at least one arm lib: $line" >> ../$temp_file
							break
						fi
					done
				fi
			fi

			popd > /dev/null
		fi
	fi
}



if ! file $third_lib_list >/dev/null && file $supported_bangbang_md5 >/dev/null && file $supported_360v2_md5 >/dev/null ; then
	 echo -e "\033[31m Please check madontory files! \033[0m" 
	 exit 0
fi

rm -rf $temp_file
rm -rf $unzip_tmp
rm -rf $support_list
rm -rf $Fail_List


	x86_missing_check			"$apk"
	mixed_javaArm_check			"$apk"
	
	check_3rd_lib "$apk" "libnqshield.so|libnqshieldx86.so"   网秦安全盾
	check_3rd_lib "$apk" "libprotectClass.so|libprotectClass_x86.so"  360加固
	check_3rd_lib "$apk" "libDexHelper.so|libDexHelper-x86.so"        "梆梆加固(付费版)"
	check_3rd_lib "$apk" "libchaosvmp.so|/artl$|/encode.dex$"     娜迦加固
	check_3rd_lib "$apk" "libCtxTFE.so"       "Citrix XenMobile"
	check_3rd_lib "$apk" "dexmaker.jar"       DexMaker
	check_3rd_lib "$apk" "libegis-x86.so|libegis.so|libegis_security.so"      "通付盾 Payegi"

	check_tencent_protection "$apk"
	check_aijiami_protection "$apk"
	check_bangbang_protection "$apk"
	check_ali_protection	"$apk"


	check_bangbang_support "$apk"

	check_cmcc	"$apk"
	check_360V2	"$apk"


	let i=i+1
	rm -rf $unzip_tmp

