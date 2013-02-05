SET NEWPAGE 0
SET SPACE 1
SET PAGESIZE 0
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET MARKUP HTML OFF 
SET WRAP OFF
SET TERMOUT OFF
-- Temporary file location and naming pattern should match with that in
-- scan_db.sh script, so that it can read the file.
SPOOL <temp_dir>/scandb_<query_name>.tmp
-- BEGIN SELECT STATEMENT
SELECT trans_id, type, state, result, created_date, created_by
FROM transactions 
WHERE created_date >= to_timestamp(sysdate) 
ORDER BY created_date ASC;
-- END SELECT STATEMENT
SPOOL off
