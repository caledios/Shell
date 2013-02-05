#===============================================================================
# Productivity and Support functions:
# ------------------------------------------------------------------------------
# - Quick automation tools and shortcuts.
# - Could be optimised or written more elegantly in some cases.
#===============================================================================

. ~/Systems/Scripts/Shell/utiba_functions.sh

#===============================================================================
# UTILS.SYSTEM
#===============================================================================

# Raises a GNOME notification with a custom message. This is useful to alert us
# when a background script has completed.
function 1notify() {
	notify-send --hint=int:transient:1 "$1";
}

# Simple util to hold execution until user presses ENTER.
function 1hold() { read -p "Press ENTER to continue"; }

# Display prompt when the last command's return value is not 0 (success).
function 1haltonerror() { 
	result=$?; 
	if [ $result -ne 0 ]; then 
		echo; 
		echo -e "\nPress Ctrl+C to exit"; 
		1hold; 
	fi; 
	return $result; 
}

# Wrapper for 'pwd' command. For future extensions, when needed.
function 1pwd() {
	pwd;
}

# Shortcut to edit bash_profile.
function 1bashprofile() {
	gedit ~/.bash_profile;
}

# Shortcut to reload bash_profile.
function 1bashprofilereload() {
	. ~/.bash_profile;
}

# If a valid path is provided as the first argument, return it. Otherwise return
# the current directory. This is useful for functions that can take a specific
# directory or current directory in the absence of the former.
function 1targetdir() { 
	if [ $1 -a -d $1 ]; then 
		echo $1; 
		return; 
	fi; 
	echo "."; 
}

# pushd without printing the directory stack.
function 1pushd() {
	pushd $1 > /dev/null;
}

# popd without printing the directory stack.
function 1popd() {
	popd $1 > /dev/null;
}

# Finds Agent processes.
function 1psumarket() {
	ps ax | grep regression | grep -E 'etc/.*.properties';
}

# Finds JBoss processes.
function 1psjboss() {
	ps ax | grep java | grep jboss;
}

# Finds the latest file in a target directory.
function 1latestfilein() {
	echo "$1/`ls -1 $1 | sort | tail -1`";
}

# A shortcut for the 'less' with options that are convenient for inspecting log 
# files.
function lesslog() {
	less -IMSN $@;
}

# Prints a horizontal line of the character supplied as the argument.
function 1hline() {
	printf "%*s" `tput cols` | tr " " $1;
}

#===============================================================================
# UTILS.UMARKET
#===============================================================================

# Shortcut to reset default agent licence.
function 1licence() {
	$UTIBA_LICENCE $AGENT_UM_1;
}

# Shortcut for checking agent statuses.
function 1check() { $UTIBA_CTL check $@; }

# Shortcut for starting agent(s).
function 1start() { 
	$UTIBA_CTL start $@; 
	1check $@; 
}

# Shortcut for starting agent(s).
function 1stop() {
	$UTIBA_CTL stop $@;
	1check $@;
}

# Shortcut for renewing default agent licence.
function 1renew() { 
	1stop $AGENT_UM_1; 
	1licence; 
	1start $AGENT_UM_1; 
	1showdbprop;
}

# Shortcut for restarting the default agent.
function 1restartumarket() {
	1restart $AGENT_UM_1;
	1check $AGENT_UM_1;
}

# Shortcut for starting agent(s).
function 1restart() {
	$UTIBA_CTL restart $@;
	1check $@;
	1notify "Agents have finished restarting"; 
}

# Monitors agent statuses.
function 1checkmonitor() { 
	DELAY=3;
	clear;
	while [ 1 ]; do
		1check > $TMP_DIR/agent_statuses.tmp;
		sleep 1; clear; pwd; echo;
		cat $TMP_DIR/agent_statuses.tmp | grep -E "$|Down"; echo; 
		i=0;
		while [ $i -lt $DELAY ]; do
			echo -n ">>> ";
			i=$(expr $i + 1);
			sleep 1;
		done;
		echo -n "Refreshing ...";
	done;
}

# Stop agents, rebuild just the Core, flush logs, and start agents again.
# Note that currently this will also clean up all JARs in the bin directory.
# Run this from a BIN directory.
function 1regbuildcore() {
	CORE_DIR=$1;
	if [ $CORE_DIR ]; then
		1pushd $CORE_DIR;
	fi;
	if [ ! -e ../etc/$FILE_UTIBA_START_CONF ]; then
		echo "ERROR: not a valid BIN directory: "`pwd`;
		1popd;
		return;
	fi;
	1stop $AGENT_UM_1;
	1pushd ../../Core;
	1antclean; 
	1antlocal;
	if [ $? -eq 0 ]; then
		1popd \
			&& 1flushlog \
			&& 1start $AGENT_UM_1 \
			&& 1showdbprop \
			&& 1notify "Rebuilding Core is complete";
	else 
		1popd;
	fi;
	if [ $CORE_DIR ]; then
		1popd;
	fi;
}

# Stop agents, do ant clean, rebuild everything, flush logs, and start agents again.
# Run this from a BIN directory.
function 1regbuildall() {
	CORE_DIR=$1;
	if [ $CORE_DIR ]; then
		1pushd $CORE_DIR;
	fi;
	if [ ! -e ../etc/$FILE_UTIBA_START_CONF ]; then
		echo "ERROR: not a valid BIN directory: "`pwd`;
		1popd;
		return;
	fi;
	1stop;
	1pushd ..;
	1antclean;
	1antlocal;
	if [ $? -eq 0 ]; then
		1popd \
			&& 1flushlog \
			&& 1start \
			&& 1showdbprop;
	else
		1popd;
	fi;
	if [ $CORE_DIR ]; then
		1popd;
	fi;
}

# Update CONF to switch to a different umarket.properties file
# Run this from a BIN directory.
function 1umarketprop() {
	SUFFIX=$1;
	sed -i "s/$KEYWORD_UM.*\>/$KEYWORD_UM$SUFFIX.properties/" ../etc/$AGENT_UM_1.conf;
	cat ../etc/$AGENT_UM_1.conf | grep -E "$KEYWORD_UM*";
}

# Clears out all log files.
# Run this from a BIN directory.
function 1flushlog() {
	find ../log/ \( -name '*.log' -o -name '*.properties' \) | xargs rm -rvf;
}

#===============================================================================
# UTILS.UMARKET.DB
#===============================================================================

# Rebuilds a standard UM instance database.
# Usage: [regression/any] 1dbrebuild
function 1dbrebuild() {
	1stop $AGENT_UM_1;
	1pushd ../db;
	rm -rf out;
	$UTIBA_BUILDDB --dbinst=xe;
	1pushd ./out/oracle;
	sh build.sh;
	1popd;
	1pwd;
	grep -rA1 ERROR `find ./out/oracle -name build_* -print`;
	1hold;
	1licence;
	1start $AGENT_UM_1;
	1check $AGENT_UM_1;
	1popd;
}

# Updates database schema owner and runner.
# e.g. [regression/any] 1dbprop [suffix]
function 1dbprop() {
	SUFFIX=$1;
	sed -i "s/umarketadm.*\>/umarketadm$SUFFIX/" ../etc/$FILE_DBPROP;
	sed -i "s/umarketrun.*\>/umarketrun$SUFFIX/" ../etc/$FILE_DBPROP;
	1showdbprop;
}

# Shortcut.
function 1dbpropreg() { 
	1dbprop _reg;
}

# Shortcut.
function 1dbpropweb() {
	1dbprop _web;
}

# Shows the database properties (schema) currently in use within a regression module.
# Usage: [regression/any] 1showdbprop
function 1showdbprop() {
	cat ../etc/db.properties | grep -E "^ga.jdbc.*.(user|owner|url)=.*$" | grep -E "user|owner|url|$KEYWORD_UM.*";
}

# Inserts an admin agent to a database.
function 1sqlinsertadmin() {
	DB=$1
	sqlplus $DB/$KEYWORD_DBAUTH@xe < $scripts/Common/db/db_insert_admin.sql; }

#===============================================================================
# SYSCONFIG
#===============================================================================

# Builds, imports, and activates a maven-based SysConfig file.
# Usage: 1sysconfigbuildactivate [SysConfig directory]
function 1sysconfigbuildactivate {
	dir=$1;
	if [ $# -eq 1 -a $dir -a -d $dir -a -f $dir/pom.xml ]; then
		1pushd $dir;
		1pushd ../regression/db \
			&& 1showdbprop \
			&& 1popd;
		1hold;
		version=`grep -m1 version pom.xml | grep -oE ">.*<" | sed "s/[>,<]//g"`;
		mvn clean install;
		zip_file=`find . -name *sysconfig*.zip`;
		echo $zip_file;
		unzip -o $zip_file;
		sysconfig_file=`find configurations -name "*.xml"`;
		echo "SysConfig file: $sysconfig_file";
		script=../regression/scripts/sysconfig.sh;
		id=`$script -i $sysconfig_file 2>&1`; # the script prints to stderr
		id=`echo $id | grep id= | sed 's/.*id=//'`;
		echo "Imported SysConfig ID: $id";
		$script -a $id;
	else
		echo "Usage: 1sysconfigbuildactivate [SysConfig directory]";
	fi
	
}

#===============================================================================
# LIFERAY
#===============================================================================

# Starts Liferay JBoss
function 1liferaystart() {
	export LAUNCH_JBOSS_IN_BACKGROUND=1;
	JBOSS_HOME=/usr/local/liferay/latest/jboss;
	1pushd $LIFERAY_HOME/jboss/bin;
	./standalone.sh -b 0.0.0.0 > log.console &
	echo $! > $JBOSS_PID_FILE;
}

# Stops Liferay JBoss
function 1liferaystop() {
	kill `cat $JBOSS_PID_FILE`;
	echo "";
}

# Deploys (copies) a file to Liferay's JBoss deploy folder.
function 1liferayjbossdeploy() {
	cp $1 $liferayjbossdeploy;
}

#===============================================================================
# JBOSS
#===============================================================================

# Starts JBoss.
function 1jbossstart() {
	JBOSS_HOME=/usr/local/utiba/jboss/latest;
	1pushd $JBOSS_HOME/bin;
	./run.sh -b 0.0.0.0 > log.console &
	echo "--------------------------------------"
	echo " JBoss Deployed WT"
	echo "--------------------------------------"
	1jbossdeployed;
	echo "--------------------------------------"
	echo " Starting JBoss with PID $!"
	echo "--------------------------------------"
	1popd;
}

# Stops JBoss.
function 1jbossstop() { 
	1pushd $JBOSS_HOME/bin;
	./shutdown.sh -S;
	1popd;
}

# Restarts JBoss.
function 1jbossrestart() {
	1jbossstop;
	sleep 12;
	1jbossstart;
}

# Displays what WT is currently deployed in JBoss.
function 1jbossdeployed() {
	1pushd $JBOSS_HOME/server/default/deploy;
	ll -rt wt*ar | sed 's/\(.*\) utiba //'; 1popd;
}

#===============================================================================
# WT
#===============================================================================

# Rebuilds and redeploys a WT EAR and starts JBoss, logging to log.console file.
function 1wtbuilddeploystart() {
	target_dir=`1targetdir $1`;
	if [ $target_dir -a -d $target_dir -a -f $target_dir/pom.xml ]; then
		1pushd $target_dir;
		mvn clean install && cd scripts && sh jboss-deploy.sh && 1jbossstart;
		1popd;
	else
		echo "ERROR: Directory not specified or not a valid WT"
	fi
}

# Step 1 of 1 in WT release, save relevant SVN logs
function 1mvnrelease1() {
	logfile="$temporary/release.`date +%Y%m%d.%H%M%S`.log";
	echo "Writing to $logfile:";
	1svnlogssincetaglast > $logfile;
	gedit $logfile;
	mvn clean install;
}

# Step 2 of 3 in WT release
function 1mvnrelease2 {
	mvn -DpreparationGoals="clean install" release:prepare;
}

# Step 3 of 3 in WT release, copy EAR to temporary directory, generate hashes
function 1mvnrelease3 {
	mvn -Dgoals="deploy" release:perform;
	cd ear/target &&
	earfile=$(find . -name *.ear) &&
	1dtachashes $earfile &&
	cp $earfile $temporary;
}

#===============================================================================
# ANT
#===============================================================================

# Runs ant using local share mirror to speed things up.
function 1antlocal() { 
	ant -Djar.dir="$SHARE_MIRROR/Software/Java";
	1haltonerror;
	1notify "Ant build completed"; }

# Runs ant clean, and possibly other stuffs.
function 1antclean() { 
	ant clean;
}

#===============================================================================
# SVN
#===============================================================================

# Recursively runs svn up.
# http://blog.mycila.com/2009/07/recursive-svn-update.html
function 1svnuptree () {
	if [ "$1" == "" ]; then
		echo "Updating all SVN projects in `pwd`..."
		1svnuptreerunner .
	else
		echo "Updating all SVN projects in $1..."
		1svnuptreerunner $1
	fi
}

# The runner for 1svnuptree.
# http://blog.mycila.com/2009/07/recursive-svn-update.html
function 1svnuptreerunner() {
	#echo "Call to update ($1)"
	if [ -d $1/.svn ]; then
		echo "Updating $1...";
		svn up $1;
	else
		# echo `ls`
		for i in `ls $1`; do
			if [ -d $1/$i ]; then
				# echo "Descending to $i..."
				1svnuptree $1/$i;
			fi
		done
	fi
}

# Check out a single trunk module by its absolute path, the same directory
# structure will be created from current directory as base.
# e.g. [Workspace] 1svnco Products/ProductOne/ModuleThree
function 1svnco() {
	svn co svn://svn/$1/trunk $1;
}

# Check out all trunks under an svn path.
# e.g. [Workspace] 1svncotree Sites/ProjectTwo
function 1svncotree() {
	for f in `svn list -R svn://svn/$1 | egrep 'trunk/$'`; do
		echo $1/`dirname $f`;
	done | \
	while read f; do
		1svnco $f; 
	done; 
}

# Diff all changes under current location using Meld.
# Usage: [SVN_module] 1svndiff [filename1 filename2 ...]
function 1svndiff() {
	svn diff --diff-cmd $scripts/Common/svn/svn_diff_meld.sh $*;
}

# Prints SVN Status then diff using meld.
# Usage: [SVN_module] 1svnstatus
function 1svnstatus() {
	svn status;
	1hold;
	1svndiff;
}

# Extract the svn URL returned by svn info command
# e.g. [SVN_module/SomeNode] 1svnbasepath
function 1svnbasepath() {
	svn info | grep URL | sed 's/URL: //' | sed 's/\/trunk//' | sed 's/\/branches.*//' | sed 's/\/tags.*//';
}

# Find out active nodes of an svn module
# Usage: [Anywhere] 1svninfomodule <path_to_an_svn_module>
function 1svnmoduleinfo() {
	target_dir=`1targetdir $1`;
	1pushd $target_dir && echo "Active nodes under: "`pwd`;
	find . -maxdepth 2 -type d -name .svn | sed 's/\.//g;s/svn//g;s/\///g' | xargs svn info | grep -E 'URL' | sed 's/URL: //';
	1popd;
}

# Run svn status on all nodes directly under an SVN module
# Usage: [Anywhere] 1svninfomodule <path_to_an_svn_module>
function 1svnmodulestatus() {
	target_dir=`1targetdir $1`;
	pushd $target_dir > /dev/null;
	echo "Active nodes under: "`pwd`;
	echo;
	for n in `find . -maxdepth 2 -type d -name .svn | sed 's/\.//g;s/svn//g;s/\///g'`; do
		echo -e "\033[1;32m$n\033[m";
		svn status -u $n;
		echo "-----------------------------------------------------------------";
	done
	popd > /dev/null;
}

# Runs both 1svnmoduleinfo then 1svnmodulestatus to quickly see the info.
function 1svnmodulecheck() {
	1svnmoduleinfo $1;
	echo; 1hold; echo;
	1svnmodulestatus $1;
}

# SVN diff of an artifact between different nodes within an SVN module.
# The purpose could be for example to see the differences in a file as it exists
# in different branches.
# Usage		: [SVN_module] 1svnmodulediff <a_node> <another_node> <the_file>
# Example	: [SVN_module] 1svnmodulediff trunk branches/USM-600 ejb/src/main/java/com/acompany/wt/aproject/JavaFile.java
function 1svnmodulediff() {
	basepath=`1svnbasepath`;
	from=$basepath"/"$1"/"$3;
	to=$basepath"/"$2"/"$3;
	echo "Source: "$from;
	echo "Target: "$to;
	1svndiff $from $to;
}

# Creates a new branch based on a source module (copy)
# Usage		: [SVN_module] 1svnbranchcreate <node_from> <node_to>
# Example	: [SVN_module] 1svnbranchcreate branches/USM-602 branches/USM-668
function 1svnbranchcreatefrom() { 
	if [ ! $1 ]; then echo -e "ERROR: please specify the source path"; return; fi;
	if [ ! $2 ]; then echo -e "ERROR: please specify the target path"; return; fi;
	echo "Create a new branch...";
	module=`1svnbasepath`;
	sourcepath=$module"/"$1;
	targetpath=$module"/"$2;
	echo "Module    : "$module;
	echo "Source    : "$sourcepath;
	echo "Target    : "$targetpath;
	1hold;
	svn cp $sourcepath $targetpath;
}

# Switch to a node within current svn module
# Usage		: [SVN_module] 1svnswitch <node>
# Example	: [SVN_module] 1svnswitch trunk
# Example	: [SVN_module] 1svnswitch tags/USM-4335
function 1svnswitch() {
	if [ ! $1 ]; then echo -e "ERROR: please specify target path"; return; fi;
	path=`1svnbasepath`;
	target=$path/$1;
	echo "Switch to: "$target;
	1hold;
	svn switch $target;
	svn info;
}

# Lists the new logs added to a module since the last release (a specific tag).
# Usage: [SVN_module] 1svnlogssincetag <tag_name>
function 1svnlogssincetag() {
	basepath=`1svnbasepath`;
	tag=$basepath"/tags/"$1;
	echo;
	echo "Basepath	: "$basepath;
	echo "Tag		: "$tag;
	echo;
	tag_rev=`svn info $tag | grep 'Last Changed Rev' | sed 's/Last Changed Rev: //'`;
	echo "Current revision "$tag_rev
	svn log $basepath"/"trunk -r $tag_rev":HEAD";
}

# Lists the new logs added to a module since a revision
# e.g. [SVN_module] 1svnlogssincerev <revision_number>
function 1svnlogssincerev() {
	svn log -r $1":HEAD";
}

# Lists an svn module's tags or branches
# Usage: [SVN_module] 1svnlist tags [sub_dir]
function 1svnlist() {
	target_dir=`1targetdir $2`;
	1pushd $target_dir;
	basepath=`1svnbasepath`;
	echo "Listing: "$basepath"/"$1;
	svn list $basepath/$1;
	1popd;
}

# Lists svn branches in current or target module
# Usage: [SVN_module] 1svnlistbranches [sub_dir]
function 1svnlistbranches() {
	1svnlist branches $1;
}

# Lists svn tags in current or target module
# Usage: [SVN_module] > 1svnlisttags [sub_dir]
function 1svnlisttags() {
	1svnlist tags $1;
}

# Lists the logs since the last tag
# Usage: [SVN_module] 1svnlogsincetaglast
function 1svnlogssincetaglast() {
	basepath=`1svnbasepath`;
	tags=$(svn log -v $basepath/tags | awk '/^   A/ { print $2 }')
	last_tag=$(echo $tags | cut -f1 -d " " | sed 's/.*\///');
	1svnlogssincetag $last_tag;
}

# EOF
