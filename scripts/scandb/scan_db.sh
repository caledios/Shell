#!/bin/sh
#===============================================================================
# DB Scanner
#
# Monitors the live contents of a specific DB table, displaying changes almost
# immediately. This is done in two steps:
# 1. Spool the results of a SELECT query into a temporary file.
# 2. Use 'watch' to highlight changes to and display new content of that temporary file.
#-------------------------------------------------------------------------------
# Todo: restrict rows in SQL file instead of using tail.
#-------------------------------------------------------------------------------
# Usage		: scan_db.sh <query_name> <database>
#===============================================================================

if [ $# -lt 2 ]; then
	echo "Usage: scan_db.sh <script> <dbowner>";
	echo "Script lookup location: $scripts/Common/scandb";
	echo "Make sure the script pools result out to scandb_<script>.tmp";
	exit 1;
fi

query_name=$1
db_owner=$2
password=$KEYWORD_DBAUTH
# Query and results files, pattern and location of the results (temporary) file
# should match with what is defined in the query file.
sql_file=$scripts/Common/scandb/$query_name.sql
tmp_file=$temporary/scandb_$query_name.tmp

watch -t -d "echo -e \"[$db_owner] $query_name\n\"; \
	exit | sqlplus $db_owner/$password@xe @$sql_file 1> /dev/null; \
	tail --lines=10 $tmp_file"
