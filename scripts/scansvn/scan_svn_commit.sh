#!/bin/sh
#===============================================================================
# Listens for new revisions on a repository path. It only does so every certain
# time period, so subsequent commits that are too close to each other might be
# missed But this is good enough for this purpose, for now.
# ------------------------------------------------------------------------------
# Possible improvement: incrementally process revision when the difference 
# between cur_rev and new_rev is more than 1.
#===============================================================================
delay=10
repo="svn://svn/"
cur_rev="-1";
#echo "Current revision: "$cur_rev
clear;
echo "Monitoring revisions at path: "$repo
while true; do
	new_rev=`svn info $repo | grep 'Revision: ' | sed 's/Revision: //'`
	#echo "Last Revision: "$new_rev
	if [ $cur_rev -ne $new_rev ]; then
		printf "%*s" `tput cols` | tr " " "-";
		#echo "Updated current revision to: "$cur_rev
		cur_rev=$new_rev
		#svn log -v -r $rev svn://svn/
		svn info $repo | grep 'Last Changed'
		echo;
		svn diff --summarize -c $cur_rev $repo
		echo;
		svn log -r $cur_rev $repo | sed '1,3d' | sed '$d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
		echo;
		#echo "Listening for new revision at "$repo" ..."
	fi
	sleep $delay;
done
