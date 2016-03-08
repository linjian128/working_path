#!/bin/bash
#set -x

third_lib_list="ThirdPartySO"
unzip_tmp="temp_unzip"
temp_file="scan_result"
support_list="360v2_bangbang_support_list"
supported_bangbang_md5="bm.check.list"
supported_360v2_md5="jm.check.list"

check_3rd_lib(){
		contain_3rd_lib=0
		if aapt l "$1" |grep -E $2 >/dev/null; then
			contain_3rd_lib=1
		fi
		if [ $contain_3rd_lib -ne 0 ]; then
			echo -e "\033[32m$1,$3 \033[0m"
			echo "$1,$3 " >> $temp_file
		fi

}
check_bangbang_support(){
	if aapt l "$1" |grep -E "libsecexe.so|libsecmain.so|libsecexe.x86.so|libsecmain.x86.so|libsecpreload.x86.so|libsecpreload.so" >/dev/null; then
		find $unzip_tmp -name libsecexe.so|xargs -i md5sum {} |awk '{print $1}'|sort|uniq > lib_md5_$1 > /dev/null
		if grep -xvf $supported_bangbang_md5 lib_md5_$1; then
			echo $1,梆梆加固, unsupported >> $support_list
		else
			echo $1,梆梆加固, supported >> $support_list
		fi
		rm lib_md5_$1
	fi
}
check_360v2_support(){
	if aapt l "$1" |grep -E "libjiagu_art.so|libjiagu.so" >/dev/null; then
		echo $1,360V2, supported >> $support_list
	fi
}


check_tencent_protection(){
	if aapt l "$1" |grep "libshell.so" >/dev/null && aapt l "$1" |grep "libmain.so" >/dev/null; then
        	echo -e "\033[32m$1, 腾讯加固  \033[0m"
		echo "$1,腾讯加固" >> $temp_file
        fi
}

check_aijiami_protection(){
	if aapt l "$1" |grep "libexec.so" >/dev/null && aapt l "$1" |grep "libexecmain.so" >/dev/null; then
        	echo -e "\033[32m$1, 爱加密  \033[0m"
		echo "$1,爱加密" >> $temp_file
        fi
}

check_ali_protection(){
	if (aapt l "$1" |grep "libmobisec.so" >/dev/null && aapt l "$1" |grep "libmobisecy1.so" >/dev/null && aapt l "$1" |grep "libmobisecz1.so" >/dev/null); then
		echo -e "\033[32m$1, Ali  \033[0m"
                echo "$1,Ali Protection" >> $temp_file
	fi
}
Upload_to_DB(){
        if [ -f "$1" ]; then
                apk_info=`cat "$1"`
                apk_name_1=`aapt d badging $2|grep "package: name="|awk -F"'" '{print $2}'`
                apk_name=${apk_name_1}-1.apk
                mysql -happtestserver -P3306  -uroot -pintel123 cv2 -e "update apk set lib_info_desc = '$apk_info' where pkg_name = '$apk_name' and app_platform='$3'"
        fi

}

x86_missing_check() {
	#apk both contains lib/x86 & lib/arm* libs need to be checked
	if aapt l "$1"|grep '^lib/x86/*'>/dev/null && aapt l "$1"|grep '^lib/armeabi*/*'>/dev/null; then  
		#if contain v7 folder, scan v7, else scan v5
		if aapt l "$1" |grep '^lib/armeabi-v7a/*' >/dev/null; then 
			need_to_check_user_lib="Yes"
			missing_user_lib="No"

			aapt l "$1" |grep '^lib/armeabi-v7a/*' | while read line
			do
				v7_lib_tmp=${line#*lib/armeabi-v7a/lib}
				v7_lib=${v7_lib_tmp%%.so*}
				if [ "X${v7_lib}" == "X" ]
				then
					continue
				fi
				#If this v7 lib is 3rd lib, need a same name lib under x86/ folder, or it would be missing x86 app
				if grep $v7_lib  $third_lib_list >/dev/null; then
					if ! aapt l "$1" |grep '^lib/x86/*'|grep $v7_lib >/dev/null; then 
						echo -e "\033[36m$1, X86 missing 3rd lib $v7_lib \033[0m"
						echo "$1, X86 missing 3rd lib $v7_lib" >> $temp_file
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
						echo "$1, X86 missing user lib in lib/armeabi-v7a/" >> $temp_file
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
					if grep $v5_lib  $third_lib_list > /dev/null; then
						if ! aapt l "$1" |grep '^lib/x86/*'|grep $v5_lib >/dev/null; then
							echo -e "\033[36m$1, X86 missing 3rd lib $v5_lib \033[0m"
							echo "$1, X86 missing 3rd lib $v5_lib" >> $temp_file
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
					echo "$1, X86 missing user lib lib/armeabi/" >> $temp_file
				#else
				#	echo $1, "not a missing x86 app"
				fi
		fi
	fi
}

mixed_javaArm_check(){
	if ! unzip "$1" -d $unzip_tmp >/dev/null; then
		echo -e "\033[31mFaild to unzip $1 \033[0m"
		exit 1
	else
		pushd $unzip_tmp >/dev/null
		#echo Scaning $1 ...
		find . -name "*.so"|grep '/lib/x86*' | while read line 
		do
			if readelf -h $line |grep Machine |grep ARM > /dev/null; then
				echo -e "\033[33m$1, Mixed app \033[0m"
				echo "$1, Mixed app" >> ../$temp_file
				break
			fi
		done

		#if ! ( find . -name "*.so"|grep '/lib/arm'>/dev/null && ! find . -name "*.so"|grep '/lib/x86*' >/dev/null); then
		# scan purejava app
		if ! aapt d badging ../"$1" |grep native-code >/dev/null; then
			if [ -d "assets/" ]; then
				find assets/ -name "*.so" | while read line
				do
					if readelf -h $line |grep Machine |grep ARM >/dev/null; then
						echo -e "\033[31m$1, PureJava app contains at least one arm lib: $line \033[0m"
						echo "$1, PureJava app contains at least one arm lib: $line" >> ../$temp_file
						break
					fi
				done
			fi
		fi

		popd > /dev/null
	fi
}

if [ ! -f $third_lib_list ]; then 
	echo -e "\033[31mNeed file $third_lib_list in this folder to scan missing x86! \033[0m"
	exit
fi

if [ -f $temp_file ]; then
	rm -rf $temp_file
fi

if [ -d $unzip_tmp ] ; then 
	rm -rf $unzip_tmp
fi

if [ -f $support_list ] ; then
	rm -rf $support_list
fi


all_apk_no=`ls *.apk|wc -l`
i=1
ls *.apk |while read apk
do
	echo "($i/$all_apk_no)   scaning $apk"
	x86_missing_check			"$apk"
	mixed_javaArm_check			"$apk"

	check_3rd_lib "$apk" "libsecexe.so|libsecmain.so|libsecexe.x86.so|libsecmain.x86.so|libsecpreload.x86.so|libsecpreload.so"        梆梆加固
	check_3rd_lib "$apk" "libnqshield.so|libnqshieldx86.so"   网秦安全盾
	check_3rd_lib "$apk" "libprotectClass.so|libprotectClass_x86.so"  360加固
	check_3rd_lib "$apk" "libjiagu_art.so|libjiagu.so"  360加固_V2
	check_3rd_lib "$apk" "libDexHelper.so|libDexHelper-x86.so"        "梆梆加固(付费版)"
	check_3rd_lib "$apk" "libchaosvmp.so|/artl$|/encode.dex$"     娜迦加固
	check_3rd_lib "$apk" "libCtxTFE.so"       "Citrix XenMobile"
	check_3rd_lib "$apk" "dexmaker.jar"       DexMaker
	check_3rd_lib "$apk" "libmegjb.so"        "CMCC Billing SDK"
	check_3rd_lib "$apk" "libegis-x86.so|libegis.so|libegis_security.so"      "通付盾 Payegi"

	check_tencent_protection "$apk"
	check_aijiami_protection "$apk"
	
	check_bangbang_support "$apk"
	check_360v2_support	"$apk"
	check_ali_protection	"$apk"
	#Upload info in tmpfile to DB
        #Upload_to_DB $tmpfile $APK $platform


	let i=i+1
	rm -rf $unzip_tmp
done 
