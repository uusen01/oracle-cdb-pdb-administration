--------------------------------------------------------------------------------
-- Script:        pdb_tablespaces.sql
-- Purpose:       Report tablespace usage per PDB from the root -- allocated, used, and
--                % of autoextend ceiling -- so space pressure in any container is caught
--                from one place without connecting to each PDB.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on CDB_DATA_FILES, CDB_FREE_SPACE, V$PDBS (or
--                SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @pdb_tablespaces.sql
--
-- Explanation:
--   * CDB_DATA_FILES / CDB_FREE_SPACE expose every PDB's tablespaces from the root, so
--     one query gives a consolidated space picture across all containers.
--   * PCT_USED_OF_MAX uses MAXBYTES where autoextend is on, reflecting the true ceiling
--     a tablespace can reach -- the number to watch to prevent ORA-01653 inside a PDB.
--   * Rows at/above the threshold are flagged ALERT; act on those PDB tablespaces first.
--   * Each PDB has its own SYSTEM/SYSAUX/USERS plus app tablespaces -- this shows them
--     all, attributed to the owning container.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 210
SET PAGESIZE 120
SET FEEDBACK OFF
COLUMN pdb_name        FORMAT A18
COLUMN tablespace_name FORMAT A20
COLUMN alloc_gb        FORMAT 999,990.00
COLUMN used_gb         FORMAT 999,990.00
COLUMN max_gb          FORMAT 999,990.00
COLUMN pct_used_of_max FORMAT 990.0
COLUMN status_flag     FORMAT A8

DEFINE warn_threshold = 85

PROMPT
PROMPT ================= TABLESPACE USAGE PER PDB (FROM ROOT) =================
WITH files AS (
    SELECT con_id, tablespace_name,
           SUM(bytes)                                       AS alloc_bytes,
           SUM(DECODE(autoextensible,'YES',maxbytes,bytes)) AS max_bytes
    FROM   cdb_data_files
    GROUP  BY con_id, tablespace_name
),
fre AS (
    SELECT con_id, tablespace_name, SUM(bytes) AS free_bytes
    FROM   cdb_free_space
    GROUP  BY con_id, tablespace_name
)
SELECT p.name                                              AS pdb_name,
       f.tablespace_name,
       ROUND(f.alloc_bytes/1024/1024/1024, 2)              AS alloc_gb,
       ROUND((f.alloc_bytes - NVL(fr.free_bytes,0))/1024/1024/1024, 2) AS used_gb,
       ROUND(f.max_bytes/1024/1024/1024, 2)                AS max_gb,
       ROUND((f.alloc_bytes - NVL(fr.free_bytes,0))*100/f.max_bytes, 1) AS pct_used_of_max,
       CASE WHEN (f.alloc_bytes - NVL(fr.free_bytes,0))*100/f.max_bytes >= &warn_threshold
            THEN 'ALERT' ELSE 'OK' END                     AS status_flag
FROM   files f
JOIN   v$pdbs p ON p.con_id = f.con_id
LEFT   JOIN fre fr ON fr.con_id = f.con_id
                  AND fr.tablespace_name = f.tablespace_name
ORDER  BY pct_used_of_max DESC;

PROMPT
PROMPT (status_flag = ALERT means PCT_USED_OF_MAX >= &warn_threshold% inside that PDB.)
PROMPT
SET FEEDBACK ON
