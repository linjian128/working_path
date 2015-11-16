#!/usr/bin/python
# FileName: getComp.py
# Function: go through the compatiblity scan results and give the compatibility info of top apps

import sys
import csv
import time
from glob import glob

wellcome_sentence = "App Compatibility Extracter V1.2"
screen_width = 100
text_width = len(wellcome_sentence)
box_width = text_width + 6
left_margin = (screen_width - box_width) // 2
text_margin = (box_width - text_width) // 2

print
print ' ' * left_margin + '+' + '-' * (box_width-2) + '+'
print ' ' * left_margin + '|' + ' ' * (box_width-2) + '|'
print ' ' * left_margin + '|' + ' ' * (text_margin-1) + wellcome_sentence + ' ' * (text_margin-1) + '|'
print ' ' * left_margin + '|' + ' ' * (box_width-2) + '|'
print ' ' * left_margin + '+' + '-' * (box_width-2) + '+'
print

if len( sys.argv ) != 5:
	print '''
Please input three compatibility files and the list of all apps, the command line should look like:
./getCom.py x86_arm_abi_file x86_abi_file no_abi_file all_apps_list
	'''
	sys.exit()

# Obtain the three compatibilty scan results from command line
x86_arm_abi = open(sys.argv[1])
x86_abi = open(sys.argv[2])
no_abi = open(sys.argv[3])
all_app = open(sys.argv[4])

# the name of the output file
outputfile = time.strftime('compinfo_%Y%m%d%H%M%S.csv')

writer = csv.writer(file(outputfile, 'w'))
writer.writerow(['URL', 'Type'])
first_round_result = [] # record the restuls obtained in the first round scan

# if an app is incompatible with account1 (x86+arm), it is actually incompatible with our device
list_x86_arm_abi = []
while True:
	line = x86_arm_abi.readline()
	if len(line) == 0: # end of line
		break
	
	list_x86_arm_abi.append(line)
	if "This app is incompatible with your device" in line:
		row = ['incompatible']
		tmpurl = line.split(' : ')[0]
		row.insert(0, tmpurl)	
		writer.writerow(row)
		first_round_result.append(tmpurl+':') # add an additional tail to aviod "short match"

# if an app is compatible with account3 (no abi), it must be a Pure Java app
list_no_abi = []
list_x86_abi = []
first = True
while True:
	line = no_abi.readline()
	if len(line) == 0: # end of line
	    break
	
	list_no_abi.append(line)
	if "This app is compatible with your device" in line:
		row = ['PureJava']
		tmpurl = line.split(' : ')[0]
		row.insert(0, tmpurl)	
		writer.writerow(row)
		first_round_result.append(tmpurl+':')

	# if an app is incompatible with account3 (no abi) but compatible with account2 (x86), it should include x86 lib
	if "This app is incompatible with your device" in line:
		url = line.split('  ')[0].split('id=')[1]
		x86_abi.seek(0) # reset the file pointer
		if first:
			while True:
				x = x86_abi.readline()
				if len(x) == 0:
					break

				list_x86_abi.append(x)
				if x.__contains__(url) and x.__contains__("This app is compatible with your device"):
					row = ['x86']
					tmpurl = line.split(' : ')[0]
					row.insert(0, tmpurl)	
					writer.writerow(row)
					first_round_result.append(tmpurl+':')
		else:
			for x in list_x86_abi:
				if x.__contains__(url) and x.__contains__("This app is compatible with your device"):
					row = ['x86']
					tmpurl = line.split(' : ')[0]
					row.insert(0, tmpurl)	
					writer.writerow(row)
					first_round_result.append(tmpurl+':')

		first = False		
				
# if an app is incompatible with account2 (x86 abi) but compatible with account1 (x86&arm abi), it should include arm lib
#x86_abi.seek(0)
#x86_arm_abi.seek(0)
for line in list_x86_abi:
#print line
	if "This app is incompatible with your device" in line:
		url = line.split('  ')[0].split('id=')[1]
		x86_arm_abi.seek(0)
		for x in list_x86_arm_abi:
			if x.__contains__(url) and x.__contains__("This app is compatible with your device"):
				row = ['ARM']
				tmpurl = line.split(' : ')[0]
				row.insert(0, tmpurl)	
				writer.writerow(row)
				first_round_result.append(tmpurl+':')

# compare with the list of all apps to check if any missed apps. They need second round of scan :(
app_wo_result = []
while True:
	line = all_app.readline()
	if len(line) == 0:
		break
	
	if not first_round_result.__contains__(line.replace('\n', ':')): # the app is not in the results of first round scan
		app_wo_result.append(line.replace('\n', ''))

#print "URL", '\t', "account1", '\t', "account2", '\t', "account3"
# the name of the output file containing missed apps
missed_outputfile = 'missed_' + outputfile

writer = csv.writer(file(missed_outputfile, 'w'))
writer.writerow(['URL', 'Account1_x86_arm', 'Account2_x86', 'Account3_no'])
for line in app_wo_result:
	row = []
	account1_info = []
	account2_info = []
	account3_info = []
	for x in list_x86_arm_abi:
		if x.__contains__(line):
#			print x
			account1_info.append(x.split(' : ')[1].replace('\n', ''))
			break

	for x in list_x86_abi:
		if x.__contains__(line):
#			print x
			account2_info.append(x.split(' : ')[1].replace('\n', ''))
			break

	for x in list_no_abi:
		if x.__contains__(line):
#			print x
			account3_info.append(x.split(' : ')[1].replace('\n', ''))
			break

	if len(account1_info) == 0:
		account1_info.append('no result')

	if len(account2_info) == 0:
		account2_info.append('no result')

	if len(account3_info) == 0:
		account3_info.append('no result')
	
	row.append(line.replace('\n', ''))
	row.append(account1_info[0])
	row.append(account2_info[0])
	row.append(account3_info[0])
#print row
	writer.writerow(row)
	
x86_arm_abi.close()
x86_abi.close()
no_abi.close()
all_app.close()
