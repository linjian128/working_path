#!/usr/bin/python
#encoding:utf-8

import urllib2 
import lxml.html
import sys
import re


f_file = open('number','r')
opl = open('LogID.csv', 'w')
 
for line in f_file.readlines():
        line = line.strip()
        url = "http://sinchtestapp.azurewebsites.net/ManageNumbers/Log/" + line
        print url
        html = urllib2.urlopen(url).read()
        print "read url done\n"
        #with open ('test', 'w') as op:
        #       op.write(html)

        tree = lxml.html.fromstring(html)

        call_log_arry = tree.xpath("//tr/td/text()|//tr/td/pre/text()")

        lenght = len(call_log_arry)
        if lenght == 0:
                print "No log ", line
                continue

        file_name = line

        op = open(file_name + '.txt', 'w')
        op.close()
        
        for i in range(lenght):
                with open(file_name +'.txt', 'a') as op:
                        message= str(i) + ' == ' + call_log_arry[i]
                        op.write(message)
                        #op.write(call_log_arry[i])
        op.close()

        print "-------------------%s--------------------"%line
        timeRe =  r"(\d{1,2}/\d{1,2}/\d{4}.*[A|P]M)"
        phonenumber = 'No..' +line + '\n'
        opl.write(phonenumber)
        if lenght < 60:
                t = -1
        else:
                t = lenght - 60
                    
        for i in range(lenght-1,t,-1):
                if re.search(r'\d{1,2}/\d{1,2}/\d{4}.*[A|P]M',call_log_arry[i]):
                        #print "i=", i
                        time = "".join(re.findall(r'\d{4}-\d{1,2}-\d{1,2}.*\d{2}.',call_log_arry[i+2]))
                        logid = "".join(re.findall(r'(?<=\"callid\": \").*(?=\")',call_log_arry[i+2]))
                        Tlogid = time + ',' + logid +'\n'
                        print Tlogid
                        opl.write(Tlogid)
        opl.write('\n')
        print "---------------------------\n\n"
                            
opl.close()                      
f_file.close()     
