#!/bin/bash


APK_DIR="$1"
APK_NAME="$2"

get_test_category_id() {
        category=`cat info.txt |grep native-code|cut -d: -f2`
        category=${category// /} #delet blank
        case $category in
        "'armeabi'")
                #v5only
                test_category_id=1;;
        "'''armeabi'")
                #v5only
                test_category_id=1;;
        "")
                #pure java
                test_category_id=2;;
        "'''armeabi-v7a'")
                #v7only
                test_category_id=3;;
        "'armeabi-v7a'")
                #v7only
                test_category_id=3;;
        "'armeabi''mips'")
                #v5 mips
                test_category_id=5;;
        "'armeabi''mips''mips-r2'")
                #v5 mips
                test_category_id=5;;
        "'armeabi''armeabi-v7a'")
                #v5v7
                test_category_id=6;;
        "'''armeabi''armeabi-v7a'")
                #v5v7
                test_category_id=6;;
        "'armeabi''armeabi-v7a''mips''mips-r2'")
                #pure java
                test_category_id=7;;
        "'armeabi-v7a''mips'")
                #v7_mips
                test_category_id=10;;
        *)
            if [[ `echo $category | grep -w -q -E "armeabi|armeabi-v7a|mips*"` -eq 0 ]];then
                if [[ `echo $category | grep -w "'armeabi'" | grep -w "'armeabi-v7a'" | grep -w "mips*"` != "" ]];then
                    #v5_v7_mips
                    test_category_id=7
                elif [[ `echo $category | grep -w "'armeabi'" | grep -w "mips*"` != "" ]];then
                    #v5_mips
                    test_category_id=5
                elif [[ `echo $category | grep -w "armeabi-v7a" | grep -w "mips*"` != "" ]];then
                    #v7_mips
                    test_category_id=10
                elif [[ `echo $category | grep -w "'armeabi'" | grep -w "'armeabi-v7a'"` != "" ]];then
                    #v5_v7
                    test_category_id=6
                elif [[ `echo $category | grep -w "'armeabi-v7a'"` != "" ]];then
                    #v7 only
                    test_category_id=3
                elif [[ `echo $category | grep -w "'armeabi'"` != "" ]];then
                    #v5 only
                    test_category_id=1
                #elif [ `echo $category | grep -w -q "mips*"` -eq 0 ];then
                    #mips only, none category currently
                fi
            elif [[ `echo $category | grep -w "jar'"` != "" ]];then
                #pure java
                test_category_id=2
            else
                #other N/A
                test_category_id=9
            fi
            ;;
        esac
        if cat info.txt |grep native-code|cut -d: -f2|grep x86 > /dev/null; then
                test_category_id=8
        fi
}


rm info.txt *.dump -f

aapt d badging "$APK_DIR" > info.txt
#cat info.txt

#apk_name=`cat info.txt |grep application-label:|cut -d"'" -f2`
apk_name=`cat info.txt |grep application-label: |cut -d: -f2| sed "s/^'//;s/'$//"`
pkg_name="$APK_NAME"
cv_name=`cat info.txt |grep "package: name="|cut -d"'" -f2`
apk_version=`cat info.txt |grep version|awk -F"versionName=" '{print $2}'|cut -d"'" -f2`
apk_version_code=`cat info.txt |grep version|awk -F"versionCode=" '{print $2}'|cut -d"'" -f2`

test_category_id=9
get_test_category_id  #set test_category_id

URL="https://play.google.com/store/apps/details?id=${APK_NAME}"
#curl --socks5-hostname proxy.jf.intel.com:1080 ${URL} -o content.tmp
curl --proxy https://child-prc.intel.com:913 ${URL} -o content.tmp
Pub_date=`cat content.tmp |grep -Po '(?<=datePublished\">).*?(?=<)'`

if [[ $Pub_date == "" ]]
then
    Pub_date=" "
fi

if [[ "$apk_name" == "" ]]
then
    apk_name="$APK_NAME"
fi

echo "$apk_name" >> "$pkg_name.dump"
echo "$pkg_name" >> "$pkg_name.dump"
echo "$cv_name" >> "$pkg_name.dump"
echo "$apk_version" >> "$pkg_name.dump"
echo "$test_category_id" >> "$pkg_name.dump"
echo "$apk_version_code" >> "$pkg_name.dump"
echo "$Pub_date" >> "$pkg_name.dump"
