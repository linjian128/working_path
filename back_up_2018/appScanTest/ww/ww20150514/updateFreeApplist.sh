#!/bin/bash
#mv topall.txt packagenames.list
pack=packagenames.list
scp -r $pack root@chaoyixx-mobl:/home/myClient/Nexus5
#scp -r $pack root@chaoyixx-mobl:/home/myClient/SM-T320
scp -r $pack root@shldeOPenLab007:/home/myClient/bayTrail
scp -r $pack root@shldeOpenLab005:/home/myClient/mofy

