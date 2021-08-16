#!/bin/bash

#SCP from local file system to remote app servers (app13 and 14 must be done manually)
for i in 01 02 03 04 05 06 07 08 09 10 11 12
do
	scp -r /opt/scripts root@adstgptlapp$i.stagingaz.int:/opt/scripts
done

#Execute the script on each server 1 to 14 (app13 and 14 must be done manually)
for i in 01 02 03 04 05 06 07 08 09 10 11 12 
do
   ssh -t root@adstgptlapp$i.stagingaz.int "/opt/scripts/dns-check-setup.sh"
   ssh -t root@adstgptlapp$i.stagingaz.int "/opt/scripts/dns-check.sh"
done

#Single Copy

#scp -r /opt/scripts root@adstgptlapp04.stagingaz.int:/opt/scripts

#ssh root@adstgptlapp04.stagingaz.int "/opt/scripts/dns-check-setup.sh"
#ssh root@adstgptlapp04.stagingaz.int "/opt/scripts/dns-check.sh"

