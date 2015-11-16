#rm -r ww/$1
#mkdir ww/$1
#cp scanToplist/*.csv ww/$1
#cp ww/*.sh ww/$1
#cp ww/*.py ww/$1
#cd ww/$1
sh getAlllist.sh
fromdos allapp.txt
#python getApkNameslist.py
echo 'succ'
