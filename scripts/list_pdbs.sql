--------------------------------------------------------------------------------
-- Script:        list_pdbs.sql
-- Purpose:       List every pluggable database in the container with its open mode,
--                restricted flag, and saved-state, so a DBA can see at a glance which
--                PDBs are open, which are mounted, and which will auto-open on restart.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on V$PDBS, DBA_PDBS, DBA_PDB_SAVED_STATES (or
--                SELECT_CATALOG_ROLE). Connect to the root container as a common user.
--
-- Example execution:
--   sqlplus / as sysdba          (or connect to CDB$ROOT service)
--   SQL> @list_pdbs.sql
--
-- Explanation:
--   * V$PDBS shows the live open mode (MOUNTED, READ WRITE, READ ONLY) and RESTRICTED
--     status for each PDB, plus the seed (PDB$SEED).
--   * DBA_PDB_SAVED_STATES shows whether a PDB has a saved open state -- the setting
--     that makes it auto-open after a CDB restart. A PDB with no saved state comes up
--     MOUNTED and must be opened manually (a common post-restart outage).
--   * CON_ID ties rows back to the container; con_id 1 = root, 2 = seed, 3+ = PDBs.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. PDB names are
--                resolved at runtime from the live container.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN pdb_name     FORMAT A22
COLUMN open_mode    FORMAT A12
COLUMN restricted   FORMAT A10
COLUMN saved_state  FORMAT A12
COLUMN total_gb     FORMAT 999,990.00
COLUMN open_time    FORMAT A20

PROMPT
PROMPT ===================== PLUGGABLE DATABASES (LIVE) =======================
SELECT p.con_id,
       p.name                                  AS pdb_name,
       p.open_mode,
       p.restricted,
       TO_CHAR(p.open_time, 'YYYY-MM-DD HH24:MI') AS open_time,
       NVL(ss.state, 'NONE')                   AS saved_state
FROM   v$pdbs p
LEFT   JOIN dba_pdb_saved_states ss
       ON ss.con_id = p.con_id
ORDER  BY p.con_id;

PROMPT
PROMPT ===================== PDB METADATA (DBA_PDBS) =========================
SELECT con_id,
       pdb_name,
       status,
       creation_scn
FROM   dba_pdbs
ORDER  BY con_id;

PROMPT
PROMPT (open_mode MOUNTED + saved_state NONE = will NOT auto-open on restart.
PROMPT  Use save_pdb_state.sql to make it auto-open.)
PROMPT
SET FEEDBACK ON
