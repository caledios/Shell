#===============================================================================
# Log File Scanner (Audit logs)
#
# Same as the standard Log File Scanner, but this one is customised to work with
# The structure and keywords in an audit log file.
#-------------------------------------------------------------------------------
# Usage		: scan_log_audit.sh <target_audit_log>
# Example	: scan_log_audit.sh audit/agent/20111110_00.log
#===============================================================================

target_log=$1

# if the target is a directory, grab the latest file
if [ -d $target_log ]; then
	target_log="$target_log/`ls -1 $target_log | sort | tail -1`";
fi

if [ ! $target_log -o ! -f $target_log ]; then
	echo "ERROR: target not specified or invalid."
else
	IFS="" # To preserve whitespaces from the read source
	clear
	echo "============ SCANLOGAUDIT ============"
	echo "Working directory : "`pwd`
	echo "Monitoring        : "$target_log
	echo "============ SCANLOGAUDIT ============"
	tail -F $target_log | sed -e '/./{H;$!d;}' -e 'x;/:process/!d;' | sed -n '/src     :/,/last_rb_address:/p' | \
	while read line ; do
		if echo "$line" | grep -q "src     :"; then 
			printf "%*s" `tput cols` | tr " " "-";
			echo
			echo $line;
		else
			echo $line;
		fi
	done
fi	


