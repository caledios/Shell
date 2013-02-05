#!/bin/sh
#===============================================================================
# DB Scanner
#
# Monitors the live contents of a specific DB table on a remote location,
# displaying changes almost immediately. This is done in two steps:
# 1. Spool the results of a SELECT query into a temporary file.
# 2. Use 'watch' to highlight changes to and display new content of that temporary file.
#-------------------------------------------------------------------------------
# Todo: restrict rows in SQL file instead of using tail
#-------------------------------------------------------------------------------
# Usage		: scan_db_remote.sh <query_name> <database> <remote_server>
#===============================================================================

query_name=$1
db_owner=$2
password=$KEYWORD_DBAUTH
remote_server=$3

watch -t "echo -e \"[$db_owner] $query_name\n\"; exit | sqlplus $db_owner/$password@\(DESCRIPTION=\(ADDRESS=\(PROTOCOL=TCP\)\(HOST=$remote_server\)\(PORT=1521\)\)\(CONNECT_DATA=\(SERVICE_NAME=xe\)\)\) @/home/irwank/FILES/System/Scripts/library/scandb/$query_name.sql 1> /dev/null; tail --lines=10 /home/irwank/Temporary/scandb_$query_name\_$db_owner\_$remote_server.tmp"

