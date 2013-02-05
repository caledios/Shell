#===============================================================================
# Log File Scanner
#
# Monitors a log file and prints out only lines of interests (lines which
# contain one or more included keywords). This is done by following a file
# through 'tail -F' command, and displaying only lines containing at least
# one word of interests and none of the excluded words.
#-------------------------------------------------------------------------------
# Usage		: scan_log.sh <target_set> <target_log>
# Example	: scan_log.sh errors event/a-umarket_1/20111110_00.log
#===============================================================================

library=$scripts/Common/scanlog
target_log=$2
target_set=$1

# File containing included keywords, case sensitive, separated by pipe.
# Must not end with a pipe or undesired whitespace.
target_set_incl=$library/$target_set.inc

# File containing excluded keywords, as above.
# e.g. ConnectException|Exception in rendering template
target_set_excl=$library/$target_set.exc

# if the target is a directory, grab the latest file
if [ -d $target_log ]; then
	target_log="$target_log/`ls -1 $target_log | sort | tail -1`";
fi

if [ $# -ne 2 ]; then
	echo -e "$0: Error - Example usage: $0 errors event/a-umarket_1/20111110_00.log";
elif [ ! -f $target_set_incl -o ! -f $target_set_excl ]; then
	echo -e "$0: Error - $1.inc/exc does not exist in $library"
else
	clear
	echo "============ SCANLOG ============"
	echo "Working directory : "`pwd`
	echo "Monitoring        : "$target_log
	echo "Target set inc    : "$target_set_incl
	echo "Target set exc    : "$target_set_excl
	echo "============ SCANLOG ============"
	tail -F $target_log | grep -vE "`cat $target_set_excl`" | grep -E "`cat $target_set_incl`"
fi


