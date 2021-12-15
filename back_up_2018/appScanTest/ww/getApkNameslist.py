'''
Created on Jun 30, 2014

@author: root
'''
import os, sys, re

if __name__ == '__main__':
    #openFIle = ''
#     with open(openFile, 'r') as op:
#         alllines = op.readlines()
    freeFile = list()
    result='packagenames.list'
    filenames = os.listdir('./')
    for f in filenames:
        if 'TopFree' in f:
            with open(f, 'r') as op:
                    alllines = op.readlines()
            for line in alllines:
                        #print line
                        l=line.split(',')
                        with open(result, 'aw') as op:
                            op.write(l[11])
                        print l[11]
            #print alllines
