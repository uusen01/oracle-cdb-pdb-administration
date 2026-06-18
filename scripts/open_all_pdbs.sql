--------------------------------------------------------------------------------
-- Script:        open_all_pdbs.sql
-- Purpose:       Open all pluggable databases that are currently MOUNTED, then confirm
--                their open mode -- the routine run after a CDB restart when PDBs did
--                not auto-open, to restore application connectivity quickly.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SYSDBA or a common user with ALTER PLUGGABLE DATABASE.
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @open_all_pdbs.sql
--
-- Explanation:
--   * ALTER PLUGGABLE DATABASE ALL OPEN opens every PDB that is mounted but closed; it
--     skips ones already open, so it is safe to run repeatedly. (Use ALL EXCEPT to
--     hold one back, or open a single PDB by name.)
--   * This addresses the classic post-restart symptom: the CDB is up but applications
--     cannot connect because their PDB is MOUNTED, not OPEN. Opening them restores
--     service immediately.
--   * For a durable fix so this is not needed after every restart, save the open state
--     with save_pdb_state.sql so PDBs auto-open with the CDB.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK ON
COLUMN name      FORMAT A22
COLUMN open_mode FORMAT A12
COLUMN restricted FORMAT A10

PROMPT
PROMPT ===================== BEFORE: CURRENT PDB STATE ========================
SELECT con_id, name, open_mode, restricted FROM v$pdbs ORDER BY con_id;

PROMPT
PROMPT ===================== OPENING ALL MOUNTED PDBs ========================
-- Opens every closed/mounted PDB; already-open PDBs are left as-is.
ALTER PLUGGABLE DATABASE ALL OPEN;

-- To open all but one (e.g., keep MAINT_PDB closed), use instead:
--   ALTER PLUGGABLE DATABASE ALL EXCEPT MAINT_PDB OPEN;
-- To open a single PDB:
--   ALTER PLUGGABLE DATABASE <pdb_name> OPEN;

PROMPT
PROMPT ===================== AFTER: CONFIRM OPEN MODE ========================
SELECT con_id, name, open_mode, restricted FROM v$pdbs ORDER BY con_id;

PROMPT
PROMPT (If you want these to auto-open after the next CDB restart, run save_pdb_state.sql.)
PROMPT
