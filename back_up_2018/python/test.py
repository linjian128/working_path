#encoding=utf-8
#!/usr/bin/python
import urllib2
import urllib  
import os 
import sys
  
req = urllib2.Request('http://linux.linuxidc.com')    
response = urllib2.urlopen(req)    
the_page = response.read()    
print the_page  
