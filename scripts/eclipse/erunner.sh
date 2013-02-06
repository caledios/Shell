#===============================================================================
# Eclipse runner
#
# The goal here is a single click or button press in Eclipse (which executes 
# this script via the External Tool feature) will perform all or as many of the
# necessary steps as possible to verify the results of code changes made. This
# may include cleaning, rebuilding, DB priming, redeploying, retesting, and
# output analysis.
#===============================================================================

junit=$resources/lib/external/junit-3.8.2.jar
bin=$workspace/ProjectOne/Core/bin
wt=$workspace/ProjectOne/WebTool
log=$temporary/erunner.tmp
dbowner=oracleowner
dbuser=oracleuser
options="-server -Xmx128M -Djava.protocol.handler.pkgs=com.utiba.delirium.test -Xdebug -Xrunjdwp:transport=dt_socket,address=8989,suspend=n,server=y"

# ------------------------------------------------------------------------------
# Available processes: comment out unwanted line(s)
# ------------------------------------------------------------------------------
dorebuildcore=true
#dojava=true
#dopretest=true
dotest=true
#doposttest=true
#docustom=true
#dojavatest=true
#dowtbuildumarket=true
#dowtbuilddeploystart=true

# ------------------------------------------------------------------------------
# Test case suite and method (disable the method variable to run all tests 
# within the suite).
# ------------------------------------------------------------------------------
suite=com.utiba.delirium.umarket.dtac.test.regressiontests.RTRTopupBonusTest
method=testValidityBonus

#===============================================================================
# Rebuilds core and restart $AGENT_UM_1 agent
#===============================================================================
function rebuildcore()
{
	$UTIBA_CTL stop $AGENT_UM_1;
	sleep 1;
	$UTIBA_CTL check $AGENT_UM_1;
	pushd ../../Core > /dev/null;
	echo "Rebuilding core ...";
	ant clean > /dev/null;
	ant -Djar.dir=$PATH_SHAREMIRROR_JAVA > $log;
	if [ $? -eq 0 ]; then
		echo "BUILD SUCCESSFUL"; popd > /dev/null; echo "Deleting old logs ..."
		find ../log/ -name '*.log' | xargs rm -rvf >> $log
		$UTIBA_CTL start $AGENT_UM_1;
		$UTIBA_CTL check $AGENT_UM_1;
		return 0;
	else
		cat $log;
		echo "BUILD FAILED";
		return 1;
	fi
}

#===============================================================================
# Pre-test
#===============================================================================
function runpretest()
{
	$UTIBA_CTL stop i-ipdispatcher_1;
	sed -i "s/umarket.*\>/umarket.properties/" ../etc/$AGENT_UM_1.conf
	$UTIBA_CTL restart $AGENT_UM_1;
	cat ../etc/$AGENT_UM_1.conf | grep -E "umarket*";
	sleep 3;
	$UTIBA_CTL check i-ipdispatcher_1;
}

#===============================================================================
# Post-test
#===============================================================================
function runposttest()
{
	password=$KEYWORD_DBAUTH;
	$UTIBA_CTL start	i-ipdispatcher_1;
	sqlplus $dbowner/$password@xe < $scripts/Common/db/db_insert_admin.sql > /dev/null;
	sqlplus $dbowner/$password@xe < $scripts/Projects/DTAC/dtac_insert_ipdbalanceenquiry.sql > /dev/null;
	$UTIBA_CTL check i-ipdispatcher_1;
	sed -i "s/umarket.*\>/$FILE_UMPROP/" ../etc/$AGENT_UM_1.conf
	cat ../etc/$AGENT_UM_1.conf | grep -E "umarket*";
	$UTIBA_CTL restart $AGENT_UM_1;
}

#===============================================================================
# Test runner
#===============================================================================
function runtest()
{
	core=`ls -1 delirium-*.jar | tail -n 1`; # get the latest core to prevent methods not found errors, etc
	cp="$junit:$core:*:../lib/*"
	printf "%*s" `tput cols` | tr " " "-"; echo;
	echo "Suite  : "$suite;
	if [ $method ]; then echo "Method : "$method; fi;
	printf "%*s" `tput cols` | tr " " "-"; echo; echo "Running tests ...";
	if [ $method ]; then java $options -cp $cp junit.textui.TestRunner -m $suite.$method 2>&1 | tee $log | grep -A100 "Time:";
	else java $options -cp $cp junit.textui.TestRunner $suite 2>&1 | tee $log | grep -A100 "Time:"; fi;
	result=$?;
	echo "Execution Status: $result";
	if [ $result -eq 1 ]; then
		tail -n 30 $log;
	fi
}

#===============================================================================
# Executes java, e.g. generating reports.
#===============================================================================
function runjava()
{
	
}

#===============================================================================
# Executes other commands, e.g. db data injections for priming.
#===============================================================================
function runcustom()
{
	
}

#===============================================================================
# Rebuilds Products/UMarket/WT
#===============================================================================
function wtbuildumarket() 
{
	echo "Rebuilding UMarket WT ...";
	pushd $umarket/WT > /dev/null; 
	mvn clean >> $log;
	mvn install >> $log;
	popd > /dev/null;
}

#===============================================================================
# Builds and deploys a WT, then starts JBoss
#===============================================================================
function wtbuilddeploystart() {
	echo "Rebuild and Deploy: $wt";
	# stops JBoss
	cd $JBOSS_HOME/bin;
	./shutdown.sh -S;
	# rebuilds and deploy WT
	cd $wt;
	mvn clean install && cd scripts && sh jboss-deploy.sh && (
		# Starts JBoss
		cd $JBOSS_HOME/bin;
		./run.sh -b 0.0.0.0 > log.console &
		cd $JBOSS_HOME/server/default/deploy; ls -lsh wt*ar | sed 's/\(.*\) utiba //';
	);
}

#===============================================================================
# Main executions
#===============================================================================

cd $bin;

if [ $dorebuildcore ]; then rebuildcore; fi;
if [ $? -eq 0 ]; then
	if [ $dojava ]; then runjava; fi;
	if [ $dojavatest ]; then java_test; fi;
	if [ $dopretest ]; then runpretest; fi;
	if [ $dotest ]; then runtest; fi;
	if [ $doposttest ]; then runposttest; fi;
	if [ $docustom ]; then runcustom; fi;
fi; 

if [ $dowtbuilddeploystart ]; then 
	wtbuilddeploystart $wt; 
fi

echo -e "\nDone!" | tee -a $log;

