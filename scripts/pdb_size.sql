--------------------------------------------------------------------------------
-- Script:        pdb_size.sql
-- Purpose:       Report the size of each PDB (datafiles + temp) from the root, for
--                capacity planning and to see how space is distributed across
--                containers in a consolidated CDB.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on CDB_DATA_FILES, CDB_TEMP_FILES, V$PDBS (or
--                SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @pdb_size.sql
--
-- Explanation:
--   * The CDB_* views aggregate across all containers; joining on CON_ID attributes
--     space to each PDB (and the root/seed). This is the consolidated-footprint view
--     you cannot get from a single PDB.
--   * Separating datafile (permanent) from tempfile size shows which PDBs carry the
--     real data vs. which just need large TEMP for sorts.
--   * Use this to balance consolidation -- e.g., spot a PDB that has grown to dominate
--     the CDB and may warrant its own resource plan or relocation.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN pdb_name    FORMAT A22
COLUMN data_gb     FORMAT 999,990.00
COLUMN temp_gb     FORMAT 999,990.00
COLUMN total_gb    FORMAT 999,990.00
COLUMN pct_of_cdb  FORMAT 990.0

PROMPT
PROMPT ======================= PDB SIZE BREAKDOWN ============================
WITH df AS (
    SELECT con_id, SUM(bytes) AS data_bytes
    FROM   cdb_data_files
    GROUP  BY con_id
),
tf AS (
    SELECT con_id, SUM(bytes) AS temp_bytes
    FROM   cdb_temp_files
    GROUP  BY con_id
)
SELECT p.con_id,
       p.name                                          AS pdb_name,
       ROUND(NVL(df.data_bytes,0)/1024/1024/1024, 2)   AS data_gb,
       ROUND(NVL(tf.temp_bytes,0)/1024/1024/1024, 2)   AS temp_gb,
       ROUND((NVL(df.data_bytes,0)+NVL(tf.temp_bytes,0))/1024/1024/1024, 2) AS total_gb,
       ROUND(NVL(df.data_bytes,0) * 100 /
             SUM(NVL(df.data_bytes,0)) OVER (), 1)      AS pct_of_cdb
FROM   v$pdbs p
LEFT   JOIN df ON df.con_id = p.con_id
LEFT   JOIN tf ON tf.con_id = p.con_id
ORDER  BY total_gb DESC;

PROMPT
SET FEEDBACK ON
