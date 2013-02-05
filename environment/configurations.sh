#===============================================================================
# COMMAND PROMPT
#===============================================================================

if [ "x$SSH_CLIENT" = "x" ]; then
	# Command prompt customization
	PS1="\[\033[1;34m\]\t\[\033[0m\] [\[\033[1;33m\]\u@\h \W\[\033[0m\]]\$ \[\033[1;35m\]"
	# Reset color back to system config after command prompt customization above
	trap 'echo -ne "\e[0m"' DEBUG
fi

# Ignores SVN folder when expanding directory path options
export FIGNORE=.svn
