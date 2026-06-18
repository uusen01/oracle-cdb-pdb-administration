--------------------------------------------------------------------------------
-- Script:        cdb_parameters.sql
-- Purpose:       Show initialization parameters that differ between the root and PDBs,
--                and list key multitenant-relevant parameters, so a DBA can see where a
--                PDB overrides the CDB default (PDBs can set many parameters locally).
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on V$SYSTEM_PARAMETER, V$PARAMETER, V$PDBS; reading per-PDB
--                values uses CONTAINERS() (SELECT on the underlying view in each PDB).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @cdb_parameters.sql
--
-- Explanation:
--   * In multitenant, many parameters can be set at the PDB level and override the CDB
--     value (ISPDB_MODIFIABLE='TRUE'). A PDB behaving differently from its siblings is
--     often a parameter override -- this script makes those visible.
--   * Section 1 lists important multitenant/operational parameters with their root value.
--   * Section 2 uses CONTAINERS() to compare a chosen parameter across all PDBs at once,
--     exposing any container that has overridden it.
--   * Knowing which parameters are PDB-modifiable prevents the mistake of setting a value
--     in the root and assuming every PDB inherits it.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. Values are
--                resolved at runtime.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 120
SET FEEDBACK OFF
COLUMN name             FORMAT A34
COLUMN value            FORMAT A40
COLUMN ispdb_modifiable FORMAT A16
COLUMN con_id           FORMAT 9990
COLUMN pdb_value        FORMAT A40

PROMPT
PROMPT ============ KEY PARAMETERS (ROOT) + PDB-MODIFIABLE FLAG ==============
SELECT name,
       value,
       ispdb_modifiable
FROM   v$system_parameter
WHERE  name IN ('sga_target','pga_aggregate_target','pga_aggregate_limit',
                'cpu_count','processes','sessions','open_cursors',
                'db_cache_size','shared_pool_size','undo_tablespace',
                'optimizer_mode','max_pdbs','enable_pluggable_database')
ORDER  BY name;

PROMPT
PROMPT ====== EXAMPLE: ONE PARAMETER COMPARED ACROSS ALL PDBs (CONTAINERS) =====
-- Change 'optimizer_mode' to any parameter you want to compare across containers.
SELECT c.con_id,
       p.name                                  AS pdb_name,
       c.value                                 AS pdb_value
FROM   CONTAINERS(v$parameter) c
JOIN   v$pdbs p ON p.con_id = c.con_id
WHERE  c.name = 'optimizer_mode'
ORDER  BY c.con_id;

PROMPT
PROMPT (ISPDB_MODIFIABLE=TRUE means a PDB can override the root value. Use ALTER SYSTEM
PROMPT  ... while connected to that PDB to set a PDB-local value.)
PROMPT
SET FEEDBACK ON
