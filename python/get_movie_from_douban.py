#encoding=utf-8  
#!/usr/bin/python  
  
import os         
import sys  
import re  
import time  
import smtplib  
import urllib  
import urllib2  
import traceback  
from urllib import urlopen  
  
page=[]  
  
def check_num_exist(data):  
	for i in range(0, len(page)):  
        	if data==page[i]:  
			return True  
			return False  
  
if __name__ == '__main__':  
	num = 0;  
	page.append('25788662')
	while num < len(page):
		print ('here in while')
		time.sleep(2)
		'''''produce url address'''  
		#url = 'http://movie.douban.com/subject/' + page[num]  
		url = 'http://movie.douban.com/explore#!type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=100'
		num += 1  
		  
		'''''get web data '''  
		req = urllib2.Request(str(url))  
		req.add_header('User-Agent','Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11')  
		  
		try:
			request = urllib2.urlopen(req)  
		      
		except urllib2.URLError, e:  
			print 'Error code urllib2.URLError: ', e.code
			continue  
		      
		except urllib2.HTTPError, e:  
			print 'Error code urllib2.HTTPError: ', e.code
			continue  
		print ('urllib2 success')      
		webdata = request.read()  
		  
		'''''get title '''  
		find=re.search(r'<title>\n(.*?).*?\n</title>',webdata)  
		if( None == find):
			continue;  
		      
		title = find.group(1).strip().decode('utf-8')  
		  
		'''''get score'''  
		find=re.search(r'<strong class=.*? property=.*?>(\d\.\d)',webdata)  
		if( None == find):  
			continue;  
		      
		score = find.group(1)  
		  
		'''''print info about the film '''  
		  
		print ('%s %s %s') %(url,title,score)  
	      
		'''''print webdata'''  
		find=re.findall(r'http://movie.douban.com/subject/(\d{7,8})', webdata)  
		if( 0 == len(find)):  
			continue;  
		      
		for i in range(0,len(find)):  
			if(False == check_num_exist(find[i])):  
				page.append(find[i])  
