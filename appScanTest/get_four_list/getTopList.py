#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import division

import socks
import socket
#socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "proxy.jf.intel.com", int(1080))
#socket.socket = socks.socksocket

import csv
import getpass
import os
import re
import sys
import urllib
import urllib2
import cookielib
import lxml.html

reload(sys)
sys.setdefaultencoding('utf-8')
#sys.setdefaultencoding('utf-8')

def buildOpener(email, password):
    # Set up our opener
    cookies = cookielib.LWPCookieJar()
    #proxy_handler = urllib2.ProxyHandler({"https" : 'https://proxy-us.intel.com:912'})
    proxy_handler = urllib2.ProxyHandler({"https" : 'https://child-prc.intel.com:913'})
    handlers = [
        #urllib2.HTTPHandler(),
        #urllib2.HTTPSHandler(),
	proxy_handler,
        urllib2.HTTPCookieProcessor(cookies)
    ]
    opener = urllib2.build_opener(*handlers)
    opener.addheaders = [('User-Agent',"Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.63 Safari/537.31")]
    urllib2.install_opener(opener)

    login_page_url = 'https://accounts.google.com/ServiceLogin?service=grandcentral'
    authenticate_url = 'https://accounts.google.com/ServiceLoginAuth?service=grandcentral'

    # Load sign in page
    login_page_contents = opener.open(login_page_url).read()

    # Find GALX value
    tree = lxml.html.fromstring(login_page_contents)
    galx_value = tree.xpath("//input[@name='GALX']")[0].values()[-1]
    #galx_match_obj = re.search(r'name="GALX"\s*value="([^"]+)"', login_page_contents, re.IGNORECASE)
    #galx_value = galx_match_obj.group(1) if galx_match_obj.group(1) is not None else ''
    print "email is " + email

    # Set up login credentials
    login_params = urllib.urlencode({
        'Email' : email,
        'Passwd' : password,
        'continue' : 'https://www.google.com',
        'GALX': galx_value
    })

    # Login
    opener.open(authenticate_url, login_params)
    # check login
    google_home_page_content = opener.open("https://www.google.com").read()
    if email in google_home_page_content:
        print "login succ"
    else:
        with open("scan_ndk.log","aw") as op:
            op.write(email + "  login fail\n")
        #sys.exit()

    for cookie in cookies:
        pass

    return opener

def getAppDetailInfo(opener,appinfo):
    for k,v in appinfo.iteritems():
        print k,v
        AppUrl = "https://play.google.com/store/apps/details?id=" + k
        print AppUrl
        try:

            content = opener.open(AppUrl).read().decode("utf-8")
        except:
            #continue
	    print "Error!"

        with open(k,"w") as fd:
             fd.write(content)
        tree = lxml.html.fromstring(content)

        ranking = v


'''
#removed by jian on 2015/10/10, new implemented below

        allContent = tree.xpath("//div[@class='content']/text()")
        datePublished = allContent[0].replace(',','').strip()
        Size = allContent[1].replace(',','').strip()
        downloads = allContent[2].replace(',','').strip()
        version = allContent[3].replace(',','').strip()
        try:
            rating = allContent[5].strip()
        except:
            rating = "N/A"
        try:
            versioncode = tree.xpath("//div[@class='dropdown-child']")[2].values()[1]
        except:
            versioncode = "N/A"
'''
        AppName = tree.xpath("//h1[@class='document-title']/div/text()")[0].replace(","," ").replace("&amp;","&").strip()
        category = tree.xpath("//a[@class='document-subtitle category']/span/text()")[0].replace("&amp;","&").replace(',','').strip()
        developer = tree.xpath("//a[@class='document-subtitle primary']/span/text()")[0].replace("&amp;","&").replace(',','').strip()
        price = tree.xpath("//meta[@itemprop='price']")[0].values()[0].strip()

#   update data formating
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

        if "$" in price:
            price = price = tree.xpath("//meta[@itemprop='price']")[0].values()[0].strip()
        else:
            price = "N/A"

        with open(resultFile,'aw') as op:
            op.write(ranking +","+ price +","+ AppName + "," + datePublished + "," + version + "," + Size + "," + downloads + "," + rating + "," + category + "," + developer + "," + AppUrl + "," + k + "\n")

def getOneCollection(cur_opener, url_prefix, index):

    PackageList = []
    appInfo = {}
    try:
   	 content = cur_opener.open(url_prefix + "start=" + str(index) + "&num=60").read().decode("utf-8")
    except:
	 return appInfo
    tree = lxml.html.fromstring(content)
    elements = tree.find_class("title")
    

    tmp = []
    for element in elements:
        tmp.append(lxml.html.tostring(element,pretty_print=True, encoding='utf-8'))

    for item in tmp:
        if "href" in item:
            package = item.split('"')[3].split('=')[1]
            PackageList.append(package)
    for pak in PackageList:
        global ranking
        appInfo[pak] = str(ranking)
        ranking = ranking + 1
    return appInfo

def getOneTopList(ListType):
    pass

if __name__ == "__main__":

    from datetime import date
    today = date.today()

    '''
    TopList = {"https://play.google.com/store/apps/collection/topselling_free?":"TopFreeInAndroidApps.csv", \
               "https://play.google.com/store/apps/collection/topselling_paid?":"TopPaidInAndroidApps.csv", \
               "https://play.google.com/store/apps/collection/topselling_paid_game?":"BastSellingInGames.csv", \
               "https://play.google.com/store/apps/collection/topgrossing?":"TopGrossingAndroidApps.csv"}
    '''

    TopList = {"https://play.google.com/store/apps/category/GAME/collection/topselling_free?":today.isoformat()+".TopFreeinGames.csv", \
               "https://play.google.com/store/apps/collection/topselling_free?":today.isoformat()+".TopFreeInAndroidApps.csv", \
               "https://play.google.com/store/apps/collection/topselling_paid?":today.isoformat()+".TopPaidInAndroidApps.csv", \
               "https://play.google.com/store/apps/category/GAME/collection/topselling_paid?":today.isoformat()+".TopPaidInGames.csv"}

    '''
    TopList = {"https://play.google.com/store/apps/collection/topselling_free?":"TopFreeInAndroidApps.csv"}
    TopList = {"https://play.google.com/store/apps/collection/topselling_free?":today.isoformat()+".TopFreeInAndroidApps.csv"}
    '''

    email = "gettoplist@gmail.com"
    password = "grove0303"
    #email = "Inteltest2015@gmail.com"
    #password = "intel@2015"

    opener = buildOpener(email, password)

    for k,v in TopList.iteritems():
        global ranking
        ranking = 1
        resultFile = v
        if os.path.isfile(resultFile):
            os.remove(resultFile)
        for index in range(0,500,60):
            getAppDetailInfo(opener, getOneCollection(opener, k, index))
