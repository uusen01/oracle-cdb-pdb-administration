--------------------------------------------------------------------------------
-- Script:        save_pdb_state.sql
-- Purpose:       Save the open state of PDBs so they AUTO-OPEN when the CDB restarts,
--                eliminating the recurring "PDB mounted but not open after reboot"
--                outage. Includes verification before and after.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SYSDBA or a common user with ALTER PLUGGABLE DATABASE.
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @save_pdb_state.sql
--
-- Explanation:
--   * By default a PDB comes up MOUNTED (closed) after a CDB restart; applications then
--     fail to connect until someone opens it. SAVE STATE records the PDB's current open
--     mode so Oracle reopens it automatically with the CDB.
--   * Open the PDB to the desired mode FIRST (READ WRITE), then save that state. The
--     saved state reflects whatever mode the PDB is in when SAVE STATE runs.
--   * DISCARD STATE removes the saved state (PDB returns to default MOUNTED on restart).
--   * Saved states are visible in DBA_PDB_SAVED_STATES.
--   * NOTE: in a Data Guard / RAC environment, save state on each instance/role as
--     appropriate.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. PDB names below
--                are placeholders -- substitute your own.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK ON
COLUMN con_name  FORMAT A22
COLUMN state     FORMAT A12
COLUMN name      FORMAT A22
COLUMN open_mode FORMAT A12

PROMPT
PROMPT ================ BEFORE: EXISTING SAVED STATES ========================
SELECT con_id, con_name, state FROM dba_pdb_saved_states ORDER BY con_id;

PROMPT
PROMPT ================ ENSURE PDBs ARE OPEN IN DESIRED MODE =================
-- Make sure the PDBs are OPEN READ WRITE before saving (adjust as needed).
ALTER PLUGGABLE DATABASE ALL OPEN;

PROMPT
PROMPT ================ SAVE OPEN STATE (AUTO-OPEN ON RESTART) ===============
-- Save for all PDBs:
ALTER PLUGGABLE DATABASE ALL SAVE STATE;

-- To save a single PDB instead:
--   ALTER PLUGGABLE DATABASE <pdb_name> SAVE STATE;
-- To undo (return a PDB to default MOUNTED on restart):
--   ALTER PLUGGABLE DATABASE <pdb_name> DISCARD STATE;

PROMPT
PROMPT ================ AFTER: CONFIRM SAVED STATES ==========================
SELECT con_id, con_name, state FROM dba_pdb_saved_states ORDER BY con_id;

PROMPT
PROMPT (PDBs with a saved OPEN state will now auto-open on the next CDB startup.)
PROMPT
