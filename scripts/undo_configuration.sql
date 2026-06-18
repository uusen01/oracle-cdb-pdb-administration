--------------------------------------------------------------------------------
-- Script:        undo_configuration.sql
-- Purpose:       Report the undo mode of a multitenant database -- SHARED (one undo
--                tablespace in the root for all containers) vs LOCAL undo (each PDB
--                has its own) -- and the undo tablespace per container. Undo mode is a
--                key 12c/19c/21c multitenant decision that affects PDB clone/relocate.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). LOCAL UNDO is the default
--                from 12.2+. Run from CDB$ROOT.
-- Privileges:    SELECT on DATABASE_PROPERTIES, CDB_TABLESPACES, V$PDBS, V$PARAMETER
--                (or SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @undo_configuration.sql
--
-- Explanation:
--   * LOCAL_UNDO_ENABLED (DATABASE_PROPERTIES) is the headline: TRUE = local undo (each
--     PDB has its own UNDO tablespace), FALSE = shared undo (single undo in the root).
--   * Local undo is required for features like PDB hot clone, relocate, and flashback
--     PDB -- so confirming it is enabled matters when planning those operations.
--   * Section 2 lists the UNDO tablespace(s) per container so you can confirm each PDB
--     actually has one under local undo, and check sizing.
--   * Pairs with the performance repo's undo_usage.sql for sizing/ORA-01555 analysis.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN property_name  FORMAT A26
COLUMN property_value FORMAT A16
COLUMN pdb_name       FORMAT A20
COLUMN tablespace_name FORMAT A22
COLUMN contents       FORMAT A12
COLUMN status         FORMAT A10
COLUMN gb             FORMAT 999,990.00

PROMPT
PROMPT ==================== UNDO MODE (LOCAL vs SHARED) =======================
SELECT property_name, property_value
FROM   database_properties
WHERE  property_name = 'LOCAL_UNDO_ENABLED';

PROMPT  (TRUE = LOCAL undo per PDB ; FALSE = SHARED undo in the root)

PROMPT
PROMPT ==================== UNDO TABLESPACES BY CONTAINER =====================
SELECT NVL(p.name, 'CDB$ROOT')                          AS pdb_name,
       t.tablespace_name,
       t.contents,
       t.status,
       ROUND(NVL(d.bytes,0)/1024/1024/1024, 2)          AS gb
FROM   cdb_tablespaces t
LEFT   JOIN v$pdbs p ON p.con_id = t.con_id
LEFT   JOIN (SELECT con_id, tablespace_name, SUM(bytes) AS bytes
              FROM cdb_data_files GROUP BY con_id, tablespace_name) d
       ON d.con_id = t.con_id AND d.tablespace_name = t.tablespace_name
WHERE  t.contents = 'UNDO'
ORDER  BY t.con_id;

PROMPT
PROMPT ==================== UNDO_TABLESPACE PARAMETER (ROOT) ==================
SELECT name, value FROM v$parameter WHERE name IN ('undo_tablespace','undo_management');

PROMPT
SET FEEDBACK ON
