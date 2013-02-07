#===============================================================================
# SPECIFIC
#===============================================================================

. ~/Systems/Scripts/Shell/utiba_aliases.sh

#===============================================================================
# UTILS
#===============================================================================

alias ..="cd ..";
alias ...="cd ../..";
alias ll='ls -lh --color=auto'
alias igrep="grep --exclude-dir=*svn* --exclude-dir=*\/vi\/* --exclude-dir=*\/fr\/* --exclude-dir=*\/es\/* --exclude-dir=*\/iw* --exclude-dir=*\/target* --exclude-dir=*\/log*"
alias igrepr="igrep -R"
alias 1findrepo="find ~/.m2/repository"

alias 1scandb="sh $scripts/Common/scandb/scan_db.sh"
alias 1scanlog="sh $scripts/Common/scanlog/scan_log.sh"
alias 1scanlogaudit="sh $scripts/Common/scanlog/scan_log_audit.sh"
alias 1scanlogjboss="sh $scripts/Common/scanlog/scan_log_jboss.sh"
alias 1scanlogliferay="sh $scripts/Common/scanlog/scan_log_liferay.sh"

#===============================================================================
# LOCATIONS
#===============================================================================

alias 2downloads="cd ~/Downloads; 1pwd"
alias 2resources="cd $resources; 1pwd"
alias 2scripts="cd $scripts; 1pwd"
alias 2systems="cd $systems; 1pwd"
alias 2tmp="cd $temporary; 1pwd"
alias 2apps="cd $apps; 1pwd"


