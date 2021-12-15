#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: Yang Sen C
# Date  : 2015-03-26
# Func  : Auto Send Email For Houdini Tracking Table


#0 8 * * 1 python /home/zxia10x/AppTestWebCrontab/AppTestWeb_AutoSendWeeklyReport.py

#
# Note:
#      1. replace table issue_create_type with table issue_category in select cmd
#      2. replace issue_create_type with issue_create_type_new in table isse_app
#      3. replace issue_category.lft_id with issue_category.id
#
#
#
# Fake Email:
#      echo "Testing - This is A Fake Email" | mailx -s "Hello World" sen.yang\@intel.com,yuhong.chen\@intel.com,jason.ji\@intel.com -- -f bits.sh.infrastructure\@intel.com
#

import os, sys, time, smtplib, base64
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage
from email.header import Header
from email.mime.image import MIMEImage
from email.Utils import COMMASPACE, formatdate
from email import Encoders

reload(sys)
type = sys.getfilesystemencoding()
#str = '哈哈';print repr(str);print str.decode('utf-8').encode('utf8')

from sshUtil import sshConnect

##Query By mysql Command
preStr = "mysql -uroot -pintel123 -Dcv2 -N -e '%s;'"


##Mail Body Template
class MailBodyTemplate_Table(object):
    '''
    Template For Houdini Tracking Table
    '''
    def __init__(self, tablename=""):
        self._tablename = '<br><font face="verdana" size="2" color="red">%s</font><br>' % tablename
        self._header = ""
        self._columns = ""
        pass

    def clear(self):
        self._tablename = ""
        self._columns = ""
        self._header = ""

    def setTableName(self, tablename):
        self._tablename = '<br><font face="verdana" size="4" color="black">%s</font><br>' % tablename

    def settableheader(self, headers=["Issue ID","APK Name","Issue Title","Severity","Platform"]):
        self._header = "<thead><tr>"
        for item in headers:
            self._header += "<th><font face='verdana' size='2' color='#AE57A4'>%s</font></th>" % item
        #
        self._header += "</tr></thead>"

    def settablecolumns(self):
        return """<tbody>%s</tbody>""" % self._columns

    def addonecolumn(self, datas=["3349", "百度浏览器", "It will crash when launch or tap any icon after launch", "High", "SOFIA"]):
        self._columns += "<tr>"
        for data in datas:
            self._columns +="<td><font face='verdana' size='2' color='#678197'>%s</font></td>" % data
        #
        self._columns += "</tr>"

    def toString(self):
        return self._tablename + "<table border='1' bordercolor='#FFE4C4' bgcolor='grey' cellspacing='0' cellpadding='6' rules='cols'>" + self._header + self._columns + "</table><br><br>" 


    def __del__(self):
        pass

##Send Email
def sendEmail(subject='Hello World', sender='Sen.Yang@intel.com', receivers=['Sen.Yang@intel.com'], mailbodytext='Testing!', attachmentlist=[] ):
    print "\n[INFO]Sending Email ... ...\n"

    #Account
    #NONE
    #Root
    EmailHandle            = MIMEMultipart('related')
    EmailHandle['Subject'] = Header( subject, charset='utf-8')#gb2312
    EmailHandle['Date']    = formatdate(localtime=True)
    EmailHandle['From']    = sender
    EmailHandle['To']      = COMMASPACE.join(receivers)
    #EmailHandle['Cc']     = 'bits.sh.infrastructure@intel.com'
    #EmailHandle['Bcc']    = ''
    EmailHandle['Date']    = formatdate()
    EmailHandle.preamble   = ''

    #Alternative
    msgAlternative = MIMEMultipart('alternative')
    EmailHandle.attach(msgAlternative)

    # Form HTML MAIL Body
    msgAlternative.attach( MIMEText(mailbodytext, 'html', 'utf-8') )
    # This example assumes the image is in the current directory
    EmbeddedImage = os.path.join( os.path.dirname( os.path.abspath(__file__)), "mail_embedded_image.png")
    if os.path.exists(EmbeddedImage):
        msgImage = MIMEImage(open(EmbeddedImage, 'rb').read())
        msgImage.add_header('Content-ID', '<embeddedimage>')
        EmailHandle.attach(msgImage)

    # For Attachment
    for file in attachmentlist:
        #
        if not os.path.exists(file):
            continue
        #
        part = MIMEBase('application','octet-stream')
        part.set_payload( open(file, 'rb').read() )
        Encoders.encode_base64(part)
        part.add_header( 'Content-Disposition', 'attachment; filename="%s"' % os.path.basename(file) )
        msgAlternative.attach(part)

    # Setting SMTP
    smtp = smtplib.SMTP('localhost', 25)
    # SendEmail
    try:
        smtp.sendmail(sender, receivers, EmailHandle.as_string())
    except Exception, e:
        print("SendEmail Exception: %s: %s\n" %(e.errno, e.strerror))
    finally:
        #Close SMTP
        smtp.close()
    print "END!"


##
def write2file(content, file):
    fh = open(file, "w")
    fh.write(content)
    fh.flush()
    fh.close()
    
    
##
def getAppNameByApkId(apk_id):
    getApknameCmd = "select apk_name from apk where apk_id=%s" #"select apk.apk_name from issue_app LEFT JOIN apk ON apk.apk_id=issue_app.apk_id"
    apkname = t.exectueCommand([preStr % getApknameCmd % apk_id], verbose=False)
    #print isinstance(apkname, list)
    if len(apkname) == 0:
        apkname = ["NULL"]
    apkname = str(apkname[0]).decode('utf-8').encode('utf8').strip()
    return apkname

def getApkLinkByApkId(apk_id):
    return "http://apptestserver.sh.intel.com/CV2/app/admin/apkedit.php?apk_id="+apk_id

def getIssueLinkByIssueId(issue_id):
    return "http://apptestserver.sh.intel.com/CV2/app/issue/issueedit.php?issue_id="+issue_id

def getUserNameByUserId(user_id):
    if user_id == "-1":
        return "NULL"
    else:
        getUsernameCmd = "select user_idsid from user where user_id=%s"
        getUsernameCmd = preStr % getUsernameCmd % user_id
        #print "[CMD] %s " % getUsernameCmd
        try:
           username = t.exectueCommand([getUsernameCmd], verbose=False)
        except Exception, e:
           return "NULL"
        finally:
            pass
           #print "[RES]", user_id, username
        if len(username) == 0:
           return "NULL"
        else:
           return username[0]
    pass

def getIssueCategoryByTypeId(issue_create_type_new):
    getCategoryName = "select type from issue_category where id=%s"
    typename = t.exectueCommand([preStr % getCategoryName % issue_create_type_new], verbose=False)
    return typename[0]


def parseQueryResults(issueResults):
    issue_info_rows = []
    for item in issueResults:
        #issue_app.issue_id, issue_app.apk_id, issue_app.issue_title, issue_severity.s_type, issue_devices.p_name, issue_create_type.create_type, issue_status_type.type_name, issue_app.issue_BZ,issue_source.sc_name,issue_app.issue_assign_to,issue_app.report_bt,user.user_idsid,issue_app.issue_update_date
        appinfo = item.split("\t")
        issue_id = appinfo[0]
        issue_link = getIssueLinkByIssueId(appinfo[0])
        issue_id_with_link = "<a href='%s'>%s</a>" % (issue_link, issue_id)
        #
        apk_name = getAppNameByApkId(appinfo[1])
        apk_link = getApkLinkByApkId(appinfo[1])
        apk_name_with_link = "<a href='%s'>%s</a>" % (apk_link, apk_name)           
        #"Severity","Platform","Type","Status","BZ/JIRA","Source","Owner","Bt Branch","Reporter"
        issue_title = appinfo[2]
        issue_severity = appinfo[3]
        issue_platform = appinfo[4]
        issue_type = appinfo[5] #getIssueCategoryByTypeId(appinfo[5])
        issue_status = appinfo[6]
        #issue_app.issue_BZ,issue_source.sc_name,issue_app.issue_assign_to,issue_app.report_bt,user.user_idsid,issue_app.issue_update_date
        issue_bz_jira = appinfo[7]
        issue_source = appinfo[8]
        issue_assigned_to = getUserNameByUserId(appinfo[9])
        issue_on_branch = appinfo[10]
        issue_created_by = appinfo[11]
        
        #user ON user.user_id=issue_app.issue_create_by
        issue_row = [issue_id_with_link, apk_name_with_link, issue_title, issue_severity, issue_platform, issue_type, issue_status, issue_bz_jira, issue_source, issue_assigned_to, issue_on_branch, issue_created_by]
        issue_info_rows.append(issue_row)
    
    return issue_info_rows
    

def sendEmail_WeekReport(mailbodytext):
    backfilename = time.strftime('%Y_WW%W_%Y%m%d_%H%M%S.html')
    write2file(mailbodytext, backfilename)
    subject = '[%s] Houdini Issue Status Tracking Weekly Email' % time.strftime('%YWW%W')
    #mailbodytext = r"发到组邮件会被认为是垃圾邮件吗?<br>"
    #subject = "Please reply to me if you receive this email"
    beginstring = "<font face='verdana'>Hi, </font><br><br>"
    endstring = """
             <font face="verdana" size="3" color="green">Best Regards<br>Houdini Infrastructure Team</font><br>
             <font face="tahoma" size="1">-----------------------------------------------------------------------------------------<br>
             Any Problem/Requirement, Please send email to bits.sh.infrastructure@intel.com<br>任何问题，您可发邮件咨询&nbsp bits.sh.infrastructure@intel.com
             </font><br>"""
    mailbodytext = beginstring + mailbodytext + endstring
    sendEmail(subject=subject, \
          #sender='bits.sh.infrastructure@intel.com', \
          sender='sen.yang@intel.com',\
          receivers=['bits_sh_runtime@intel.com','bits.houdini.translator@intel.com','sophie.h.chen@intel.com', 'sherry.ma@intel.com','guokai.ma@intel.com','jiex.wang@intel.com','xiangqunx.zuo@intel.com','li.l.yin@intel.com','Guotao.zhong@intel.com', 'Yiqiang.Li@intel.com', 'JianX.lin@intel.com', 'xunx.Lei@intel.com', 'sen.yang@intel.com'], \
          #receivers=['sen.yang@intel.com'],\
          #receivers=['sen.yang@intel.com','Guotao.zhong@intel.com', 'Yiqiang.Li@intel.com', 'Jason.Ji@intel.com', 'JianX.lin@intel.com', 'Yuhong.chen@intel.com'], \
          mailbodytext=mailbodytext, \
          attachmentlist=[] 
          )
    print "Email Sended Successfully!"
    


if __name__ == '__main__':
    #Mail Body
    mailbodytext = ""
    #Tracking Table Name
    headers = ["Issue ID","APK Name","Issue Title","Severity","Platform","Type","Status","BZ/JIRA","Source","Owner","Bt Branch","Reporter"]
    #Table Template
    m = MailBodyTemplate_Table()
    
    #SSH Connect    
    t = sshConnect(host='10.239.178.114', port=22, usrName='zxia10x', passWd='intel123', logfile = "apptestweb.log")
    t.exectueCommand(["whoami;w;uptime"],verbose=True)
    
    
    #------------------------------------------------------------
    ##Need assign Open Issues
    ##issue status=”under investigation” & owner =””
    ##where issue_app.issue_status=2 and issue_app.issue_assign_to=-1
    #------------------------------------------------------------
    m.clear()
    #m.setTableName("Need assign Open Issues")
    m.settableheader(headers)
    
    select_cmd = "select issue_app.issue_id, issue_app.apk_id, issue_app.issue_title, issue_severity.s_type, issue_devices.p_name, issue_category.type, issue_status_type.type_name, issue_app.issue_BZ,issue_source.sc_name,issue_app.issue_assign_to,issue_app.report_bt,user.user_idsid,issue_app.issue_update_date from issue_app LEFT JOIN issue_severity ON issue_severity.s_id=issue_app.issue_severity LEFT JOIN issue_devices ON issue_devices.p_id=issue_app.platform LEFT JOIN issue_status_type ON issue_status_type.type_id=issue_app.issue_status LEFT JOIN issue_source ON issue_source.sc_id=issue_app.source LEFT JOIN user ON user.user_id=issue_app.issue_create_by LEFT JOIN issue_category ON issue_category.id=issue_app.issue_create_type_new"
    where_cmd  = "where issue_app.issue_status=2 and issue_app.issue_assign_to=-1"
    
    queryNeedAssignedOpenIssuesCmd = select_cmd + " " + where_cmd
    OpenIssues = t.exectueCommand([preStr % queryNeedAssignedOpenIssuesCmd], verbose=False)

    m.setTableName("Need assign Open Issues (%d)" % len(OpenIssues) )
    if len(OpenIssues):
        for info in parseQueryResults(OpenIssues):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString()        
    
    
    #------------------------------------------------------------
    ##High open Issues
    ##issue status=”under investigation” & Severity =”High” & owner !=””
    ##where issue_app.issue_status=2 and issue_app.issue_severity=2 and issue_app.issue_assign_to!=-1
    #------------------------------------------------------------
    m.clear()
    #m.setTableName("High open Issues")
    m.settableheader(headers)
    #
    select_cmd = "select issue_app.issue_id, issue_app.apk_id, issue_app.issue_title, issue_severity.s_type, issue_devices.p_name, issue_category.type, issue_status_type.type_name, issue_app.issue_BZ,issue_source.sc_name,issue_app.issue_assign_to,issue_app.report_bt,user.user_idsid, issue_app.issue_update_date from issue_app LEFT JOIN issue_severity ON issue_severity.s_id=issue_app.issue_severity LEFT JOIN issue_devices ON issue_devices.p_id=issue_app.platform LEFT JOIN issue_status_type ON issue_status_type.type_id=issue_app.issue_status LEFT JOIN issue_source ON issue_source.sc_id=issue_app.source LEFT JOIN user ON user.user_id=issue_app.issue_create_by LEFT JOIN issue_category ON issue_category.id=issue_app.issue_create_type_new"
    where_cmd = "where issue_app.issue_status=2 and issue_app.issue_severity=2 and issue_app.issue_assign_to!=-1"
    #
    queryHighOpenIssueCmd = select_cmd + " " + where_cmd
    HighOpenIssues = t.exectueCommand([preStr % queryHighOpenIssueCmd], verbose=True)
    #
    m.setTableName("High open Issues (%d)" % len(HighOpenIssues) )
    if len(HighOpenIssues):
        for info in parseQueryResults(HighOpenIssues):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString()   
     
    #------------------------------------------------------------
    ##Medium open Issues
    ##issue status=”under investigation” & Severity =”Medium”
    ##where issue_app.issue_status=2 and issue_app.issue_severity=3 and issue_app.issue_assign_to!=-1
    #------------------------------------------------------------
    m.clear()
    #m.setTableName("Medium open Issues")
    m.settableheader(headers)
    where_cmd = "where issue_app.issue_status=2 and issue_app.issue_severity=3 and issue_app.issue_assign_to!=-1"
    queryMediumOpenIssueCmd = select_cmd + " " + where_cmd
    MediumOpenIssues = t.exectueCommand([preStr % queryMediumOpenIssueCmd], verbose=True)
    #
    m.setTableName("Medium open Issues (%d)" % len(MediumOpenIssues) )
    if len(MediumOpenIssues):
        for info in parseQueryResults(MediumOpenIssues):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString()           
    
    
    #Query item happend last week
    lastweek = 'and YEARWEEK(date_format(issue_app.issue_update_date,"%Y-%m-%d")) = YEARWEEK(now())-1'
    
    #------------------------------------------------------------
    ##Last week Implemented Issues
    ##issue_status_type=7,     #issue_app.issue_severity=7
    ##where issue_app.issue_status=7 and issue_app.issue_assign_to!=-1
    #------------------------------------------------------------  
    m.clear()
    #m.setTableName("Last week Implemented Issues")
    m.settableheader(headers)
    where_cmd = "where issue_app.issue_status=7 and issue_app.issue_assign_to!=-1"
    queryLastWeekImplementedIssueCmd = select_cmd + " " + where_cmd + " " + lastweek
    LastWeekImplementedIssue = t.exectueCommand([preStr % queryLastWeekImplementedIssueCmd], verbose=True)
    #
    m.setTableName("Last week Implemented Issues (%d)" % len(LastWeekImplementedIssue) )
    if len(LastWeekImplementedIssue):
        for info in parseQueryResults(LastWeekImplementedIssue):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString() 
    
    #------------------------------------------------------------
    ##Last week Verified Issues
    ##issue_status_type=3,     #issue_app.issue_severity=3
    ##where issue_app.issue_status=3 and issue_app.issue_assign_to!=-1
    #------------------------------------------------------------  
    m.clear()
    #m.setTableName("Last week Verified Issues")
    m.settableheader(headers)
    where_cmd = "where issue_app.issue_status=3 and issue_app.issue_assign_to!=-1"
    queryLastWeekVerifiedIssueCmd = select_cmd + " " + where_cmd + " " + lastweek
    LastWeekVerifiedIssue = t.exectueCommand([preStr % queryLastWeekVerifiedIssueCmd], verbose=True)
    #
    m.setTableName("Last week Verified Issues (%d)" % len(LastWeekVerifiedIssue) )
    if len(LastWeekVerifiedIssue):
        for info in parseQueryResults(LastWeekVerifiedIssue):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString() 
       
    #------------------------------------------------------------
    ##Last week Closed  Issues
    ##Transferred -> 8 / Closed->4 / WontFix->6 / FutureFix->9
    ##issue_app.issue_severity=8
    #where issue_app.issue_assign_to!=-1 and (issue_app.issue_status==8 or issue_app.issue_status==4 or issue_app.issue_status==6 or issue_app.issue_status==9 )
    #------------------------------------------------------------  
    m.clear()
    #m.setTableName("Last week Closed  Issues")
    m.settableheader(headers)
    where_cmd = "where issue_app.issue_assign_to!=-1 and (issue_app.issue_status=8 or issue_app.issue_status=4 or issue_app.issue_status=6 or issue_app.issue_status=9 )"
    queryLastWeekClosedIssueCmd = select_cmd + " " + where_cmd + " " + lastweek
    LastWeekClosedIssue = t.exectueCommand([preStr % queryLastWeekClosedIssueCmd], verbose=True)
    #  
    m.setTableName("Last week Closed  Issues (%d)" % len(LastWeekClosedIssue) )
    if len(LastWeekClosedIssue):
        for info in parseQueryResults(LastWeekClosedIssue):
            m.addonecolumn(info)
    #construct mail body
    mailbodytext += m.toString() 
        
    sendEmail_WeekReport(mailbodytext)  
    t.close()
    sys.exit()

    pass
    
