#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import lxml.html

#t_file ='com.outfit7.talkingangelafree'
t_file ='se.feomedia.pixduel.us.lite'
#t_file ='com.prettysimple.criminalcaseandroid'
with open(t_file,'r') as txt:
	f = txt.read()


#print re.search('Additional information',f)

#print re.search('super', 'insuperable').span()

tree = lxml.html.fromstring(f)

allContent = tree.xpath("//div[@class='content']/text()")
#datePublished = allContent[0].replace(',','').strip()
#Size = allContent[1].replace(',','').strip()
#downloads = allContent[2].replace(',','').strip()
#version = allContent[3].replace(',','').strip()
#rating = allContent[5].strip()

AppName = tree.xpath("//h1[@class='document-title']/div/text()")[0].replace(","," ").replace("&amp;","&").strip()
category = tree.xpath("//a[@class='document-subtitle category']/span/text()")[0].replace("&amp;","&").replace(',','').strip()
developer = tree.xpath("//a[@class='document-subtitle primary']/span/text()")[0].replace("&amp;","&").replace(',','').strip()
price = tree.xpath("//meta[@itemprop='price']")[0].values()[0].strip()


#----------Updated-----#
try:
	Size  = tree.xpath("//div[@itemprop='fileSize']/text()")[0].replace(',','').strip()
except:
	Size = "N/A"
try:
	downloads  = tree.xpath("//div[@itemprop='numDownloads']/text()")[0].replace(',','').strip()
except:
	downloads = "N/A"
try:
	datePublished  = tree.xpath("//div[@itemprop='datePublished']/text()")[0].replace(',','').strip()
except:
	datePublished  = "N/A"
try:
	version  = tree.xpath("//div[@itemprop='softwareVersion']/text()")[0].strip()
except:
	version  = "N/A"
try:
	rating  = tree.xpath("//div[@itemprop='contentRating']/text()")[0].strip()
except:
	rating  = "N/A"

print t_file

print "AppName: " + AppName
print "category: " + category
print "developer: " + developer
print "datePublished: " + datePublished
print "Size: " + Size
print "downloads: " + downloads
print "version: " + version
print "rating: " + rating
print "price: " + price
#print allContent
