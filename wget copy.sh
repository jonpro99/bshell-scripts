#!/bin/sh

#
# Generated on Wed Oct 09 11:58:52 CDT 2019
# Start of user configurable variables
#
LANG=C
export LANG

#Trap to cleanup cookie file in case of unexpected exits.
trap 'rm -f $COOKIE_FILE; exit 1' 1 2 3 6 

# SSO username 
printf 'SSO User Name:' 
read SSO_USERNAME

# Path to wget command
WGET=/usr/bin/wget

# Log directory and file
LOGDIR=.
LOGFILE=$LOGDIR/wgetlog-$(date +%m-%d-%y-%H:%M).log

# Print wget version info 
echo "Wget version info: 
------------------------------
$($WGET -V) 
------------------------------" > "$LOGFILE" 2>&1 

# Location of cookie file 
COOKIE_FILE=$(mktemp -t wget_sh_XXXXXX) >> "$LOGFILE" 2>&1 
if [ $? -ne 0 ] || [ -z "$COOKIE_FILE" ] 
then 
 echo "Temporary cookie file creation failed. See $LOGFILE for more details." |  tee -a "$LOGFILE" 
 exit 1 
fi 
echo "Created temporary cookie file $COOKIE_FILE" >> "$LOGFILE" 

# Output directory and file
OUTPUT_DIR=.
#
# End of user configurable variable
#

# The following command to authenticate uses HTTPS. This will work only if the wget in the environment
# where this script will be executed was compiled with OpenSSL.
# 
 $WGET  --secure-protocol=auto --save-cookies="$COOKIE_FILE" --keep-session-cookies --http-user "$SSO_USERNAME" --ask-password  "https://edelivery.oracle.com/osdc/cliauth" -O /dev/null 2>> "$LOGFILE"

# Verify if authentication is successful 
if [ $? -ne 0 ] 
then 
 echo "Authentication failed with the given credentials." | tee -a "$LOGFILE"
 echo "Please check logfile: $LOGFILE for more details." 
else
 echo "Authentication is successful. Proceeding with downloads..." >> "$LOGFILE" 
 $WGET  --load-cookies="$COOKIE_FILE" --save-cookies="$COOKIE_FILE" --keep-session-cookies "https://edelivery.oracle.com/osdc/softwareDownload?fileName=V46095-01_1of2.zip&token=SDFDSzhqYmlLSDUydEpGcmg2S0x1QSE6OiFmaWxlSWQ9NzIxNjI4ODEmZmlsZVNldENpZD04MjY4NzEmcmVsZWFzZUNpZHM9ODYxNzYmcGxhdGZvcm1DaWRzPTM1JmRvd25sb2FkVHlwZT05NTc2MSZhZ3JlZW1lbnRJZD01OTQ0NzczJmVtYWlsQWRkcmVzcz1ldmlhbnVldmFAYXByaXZhLmNvbSZ1c2VyTmFtZT1FUEQtRVZJQU5VRVZBQEFQUklWQS5DT00maXBBZGRyZXNzPTQuMTYuMTUzLjE4JnVzZXJBZ2VudD1Nb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvNzYuMC4zODA5LjEzMiBTYWZhcmkvNTM3LjM2JmNvdW50cnlDb2RlPVVT" -O "$OUTPUT_DIR/V46095-01_1of2.zip" >> "$LOGFILE" 2>&1 
 $WGET --load-cookies="$COOKIE_FILE" "https://edelivery.oracle.com/osdc/softwareDownload?fileName=V46095-01_2of2.zip&token=a1NDMWdrNEpodU5Ba3U1TVRSbDlOQSE6OiFmaWxlSWQ9NzIxNjI4OTEmZmlsZVNldENpZD04MjY4NzEmcmVsZWFzZUNpZHM9ODYxNzYmcGxhdGZvcm1DaWRzPTM1JmRvd25sb2FkVHlwZT05NTc2MSZhZ3JlZW1lbnRJZD01OTQ0NzczJmVtYWlsQWRkcmVzcz1ldmlhbnVldmFAYXByaXZhLmNvbSZ1c2VyTmFtZT1FUEQtRVZJQU5VRVZBQEFQUklWQS5DT00maXBBZGRyZXNzPTQuMTYuMTUzLjE4JnVzZXJBZ2VudD1Nb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvNzYuMC4zODA5LjEzMiBTYWZhcmkvNTM3LjM2JmNvdW50cnlDb2RlPVVT" -O "$OUTPUT_DIR/V46095-01_2of2.zip" >> "$LOGFILE" 2>&1 
fi 

# Cleanup
rm -f "$COOKIE_FILE" 
echo "Removed temporary cookie file $COOKIE_FILE" >> "$LOGFILE" 

