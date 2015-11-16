from sshutil import sshConnect
#SSH Connect    
t = sshConnect(host='10.239.178.114', port=22, usrName='zxia10x', passWd='intel123', logfile = "apptestweb.log")
t.exectueCommand(["whoami;w;uptime"],verbose=True)

