#!/usr/bin/env python

import os
import sys
import MySQLdb as mydb
from sets import Set

try:
    #conn = mydb.connect('apptestserver','root','intel123','cv2', charset='utf8')
    conn = mydb.connect(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4], charset='utf8')
    cur = conn.cursor()
    cur.execute("select version()")
    version = cur.fetchone()
    # print "MySQL Version:   %s" % version
except mydb.Error,e:
    print "Error %d:    %s" %(e.args[0], e.args[1])
    sys.exit(-1)

l_call_lists = []
apks = Set()
sql_insert_all = Set()
for f in os.listdir("./report"):
    if f.endswith(".call.list"):
        l_call_lists.append(f)

for call_list in l_call_lists:
    lib_name = call_list.split(".call.list")[0]
    with open("./report/" + call_list) as fd:
        all_lines = fd.readlines()
        for line in all_lines:
            content = line.split("\t")
            api = content[0]
            apk = content[1]
            apks.add(apk)
            sql_insert = "insert into cv2.non_ndk_lib_api (api,apk,lib) values('%s','%s','%s');" %(api,apk,lib_name)
            sql_insert_all.add(sql_insert)

print("non_ndk_apks :   %d" %len(apks))
print("apis         :   %d" %len(sql_insert_all))

for apk in apks:
    sql_delete = "delete from cv2.non_ndk_lib_api where apk = '%s';" % apk
    cur.execute(sql_delete)
    conn.commit()

for sql in sql_insert_all:
    cur.execute(sql)
    conn.commit()

if conn:
    conn.close()
