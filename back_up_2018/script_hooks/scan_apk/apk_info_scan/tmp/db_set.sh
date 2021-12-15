
desc="It is a Bangbang protected APK \n"

date="2014-06-18"

#mysql -h10.239.51.146 -P3306  -uroot -pintel123 cv2 -e "update apk set lib_info_desc = '$desc' where pkg_name = 'com.pandoomobile.GemsJourney-1.apk'"

mysql -h10.239.51.146 -P3306  -uroot -pintel123 cv2 -e "update apk set update_date = '$date' where pkg_name = 'com.pandoomobile.GemsJourney-1.apk'"
