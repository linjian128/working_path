#!/usr/bin/env python
#encoding:utf-8

import sys
import types
import MySQLdb as mydb
from xlrd import open_workbook

reload(sys)
sys.setdefaultencoding('utf-8')

if len(sys.argv) < 2:
    print '''
    Usage:
        upload_toplist.py date file
        ex.
        upload_toplist.py 2014-05-12 WW20_Toplist.xlsx
    '''
    sys.exit(-1)

try:
    conn = mydb.connect('apptestserver','root','intel123','cv2', charset='utf8')
    cur = conn.cursor()
    cur.execute("select version()")
    version = cur.fetchone()
    # print "MySQL Version:   %s" % version
except mydb.Error,e:
    print "Error %d:    %s" %(e.args[0], e.args[1])
    sys.exit(-1)

update_date = sys.argv[1]
xls_file    = sys.argv[2]

xls_result = open_workbook(xls_file,"rb")

all_sqls = []

for sheet in xls_result.sheets():
    if "Paid" in sheet.name or "paid" in sheet.name:
        ispaid="1"
        PAID=True
        FREE=False
    elif "Free" in sheet.name or "free" in sheet.name:
        ispaid="0"
        PAID=False
        FREE=True
    else:
        print("Unexpect sheet name: %s" % sheet.name)
        continue
    if "Apps" in sheet.name:
        APP = True
        GAME = False
    elif "Games" in sheet.name:
        APP = False
        GAME = True
    else:
        # print("Unexpect sheet name: %s" % sheet.name)
        continue
    if PAID:
        if APP:
            top_list = "TopPaid"
        else:
            top_list = "TopPaidGame"
    else:
        if APP:
            top_list = "TopFree"
        else:
            top_list = "TopFreeGame"
    count=0
    for row in range(sheet.nrows):
        count=count+1
        values = []
        for col in range(sheet.ncols):
            if type(sheet.cell(row,col).value) is types.FloatType and col == 0:
                values.append(str(int(sheet.cell(row,col).value)).replace("'",""))
            else:
                values.append(str(sheet.cell(row,col).value).replace("'",""))
        app_name = values[2].strip()
        pkg_name = values[11].strip()
        app_version = values[4].strip()
        if app_version == "Varies with device":
            app_version = "VWD"
        app_version = app_version.strip()
        publish_date = values[3].strip()
        publish_date = publish_date.replace(" ","-").replace("January","1").replace("February","2").replace("March","3").replace("April","4").replace("May","5").replace("June","6").replace("July","7").replace("August","8").replace("September","9").replace("October","10").replace("November","11").replace("December","12")
        tmp = publish_date.split("-")
        publish_date = tmp[2] + "-" + tmp[0] + "-" + tmp[1]
        publish_date = publish_date.strip()
        ranking = values[0].strip()
        ispaid = ispaid.strip()
        price = values[1].strip()
        size = values[5].strip()
        if size == "Varies with device":
            size = "VWD"
        size = size.strip()
        download = values[6].strip()
        rating = values[7].strip()
        category = values[8].strip()
        top_list = top_list.strip()
        ndk_info = values[12].strip()
        if ndk_info == "incompatible":
            ndk_info = "Incomp"
        ndk_info = ndk_info.strip()
        update_date = update_date.strip()

        one_record = [app_name,pkg_name,app_version,publish_date,ranking,ispaid,price,size,download,rating,category,top_list,ndk_info,update_date]
        if not all(one_record):
            print "broken data  :   "
            print one_record
            sys.exit(-1)
        else:
            sql="insert into cv2.google_play_app_dynamic (app_name, pkg_name, app_version, publish_date, ranking, ispaid, price, size, download, rating, category, top_list, ndk_info, update_date) values('"+ app_name + "','" + pkg_name + "','" + app_version + "','" + publish_date + "','" + ranking + "','" + ispaid + "','" + price + "','" + size + "','" + download + "','" + rating + "','" + category + "','" + top_list + "','" + ndk_info + "','" + update_date + "'" + ")"
            all_sqls.append(sql)

    print sheet.name + "    :   " + str(count)

for sql in all_sqls:
    cur.execute(sql)
    conn.commit()

if conn:
    conn.close()
