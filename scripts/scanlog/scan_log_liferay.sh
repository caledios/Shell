#===============================================================================
# Log File Scanner (JBoss)
#
# Same as the standard Log File Scanner, but this one is customised to work with
# Liferay JBoss logs and will launch a browser page on successful start.
#-------------------------------------------------------------------------------
# Usage		: scan_log_liferay.sh <target_set> <target_log>
# Example	: scan_log_liferay.sh liferay log.console
#===============================================================================

# Sets of files containing included and excluded keywords, case sensitive,
# separated by pipe. Must not end with a pipe or undesired whitespace.
# e.g. Param|WARN|Exception|Failed|not Found|not found
# The file containing included keywords will be $set.inc
# The file containing excluded keywords will be $set.exc
set=$1
log_file=$2
library=$scripts/Common/scanlog
open_url=http://localhost:8080

if [ ! -f $library/$set.inc -o ! -f $library/$set.exc ]; then
	echo -e "$0: Error - $set.inc/exc does not exist in $library"
else
	clear
	echo "============ SCANLOG ============"
	echo "Working directory : "`pwd`
	echo "Monitoring        : "$log_file
	echo "Target set        : "$set
	echo "============ SCANLOG ============"
	tail -fn0 $log_file | \
	while read line ; do
		echo "$line" | grep -E "`cat $library/$set.inc`" | \
		grep -vE "`cat $library/$set.exc`"
		if echo "$line" | grep -q "JBAS018559: Deployed \"ROOT.war\""; then 
			echo "-----------------------------------------"
			echo "     LIFERAY READY: opening firefox"
			echo "-----------------------------------------"
			firefox $open_url;
			notify-send --hint=int:transient:1 "Liferay is ready on Firefox";
		fi
	done
fi
