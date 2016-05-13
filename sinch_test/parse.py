#!/usr/bin/python
#encoding:utf-8

import urllib2 
import lxml.html
import sys



f_file = open("number")
 
while 1:
	line = f_file.readline().strip()
	if not line:
		break
	url = "http://sinchtestapp.azurewebsites.net/ManageNumbers/Log/" + line
	html = urllib2.urlopen(url).read()

	with open ('test', 'w') as op:
		op.write(html)

	tree = lxml.html.fromstring(html)


	call_log_arry = tree.xpath("//tr/td/text()|//tr/td/pre/text()")

	lenght = len(call_log_arry)

	file_name = line
	for i in range(lenght):
		with open(file_name +'.txt', 'a') as op:
			op.write(call_log_arry[i])
#print call_log_arry[1]
  
  
  
  
