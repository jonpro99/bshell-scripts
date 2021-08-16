#!/bin/sh

#create the lastip file
touch /tmp/lastip

#Add the dns-check script to the crontab and run every 5 minutes
touch /var/spool/cron/root
echo "*/5 * * * * /opt/scripts/dns-check.sh" >> /var/spool/cron/root
