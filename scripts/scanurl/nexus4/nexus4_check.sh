#!/bin/sh
#===============================================================================
# Simple script to monitor changes in stock status of Nexus 4 16GB on Google 
# Play's website. Send email notification when changes are detected. This could
# be run by cron job every 10 minutes to give a reasonable chance to get the
# device before it becomes sold out again (which won't be too long, usually).
#===============================================================================
cd /home/irwank/Systems/Scripts/Projects/Other/Nexus4
html_file=out
stock_history=history
touch $stock_history
wget -qO $html_file "https://play.google.com/store/devices/details?id=nexus_4_16gb"

# Get the stock status
stock_status=`grep -oP "hardware-inventory-status\">(.*?)<|hardware-large-print\">(.*?)<" out | sed 's/.*>//;s/<.*//'`

# If it is a new status, record it, then send notification email
tail -1 $stock_history | grep -q "$stock_status"

result=$?

if [ $result -eq 1 ]; then
	# 1 means no match was found in history
	echo "New stock status detected: $stock_status";
	echo "`date` Stock status: $stock_status" >> $stock_history;
	cat email.nexus4 | sed "s/stock_status/$stock_status/" | /usr/sbin/ssmtp -vt;
fi

