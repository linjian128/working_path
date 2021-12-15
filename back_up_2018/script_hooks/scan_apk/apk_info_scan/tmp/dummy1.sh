#printf "$1, $2 \n"|tee -a /home/Git-Apk/.git/hooks/apk_info_scan/dum.log

APK=$1

BBP="Bangbang Protected: Yes\n"

mysql -h10.239.51.146 -P3306  -uroot -pintel123 cv2 -e "update apk set lib_info_desc = '$BBP' where pkg_name = '$APK'"

