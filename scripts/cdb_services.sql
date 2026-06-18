--------------------------------------------------------------------------------
-- Script:        cdb_services.sql
-- Purpose:       Provide a CDB-wide inventory of all services across every container --
--                root and PDBs -- with their network names, to verify the full
--                connection topology of a multitenant database in one place.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on CDB_SERVICES, V$ACTIVE_SERVICES, V$PDBS (or
--                SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @cdb_services.sql
--
-- Explanation:
--   * This is the container-level companion to pdb_services.sql: rather than focusing on
--     one PDB's app service, it inventories EVERY service in the CDB (root + all PDBs),
--     including internal ones, so you can audit the complete connection surface.
--   * V$ACTIVE_SERVICES shows what is actually running/registered now; CDB_SERVICES shows
--     what is defined. Comparing the two reveals defined-but-not-running services.
--   * Useful after consolidation, cloning, or relocation to confirm every container is
--     reachable by the intended service and no stray services linger.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 120
SET FEEDBACK OFF
COLUMN container     FORMAT A20
COLUMN service_name  FORMAT A36
COLUMN network_name  FORMAT A36
COLUMN running       FORMAT A8
COLUMN cnt           FORMAT 9990

PROMPT
PROMPT ===================== SERVICE COUNT BY CONTAINER =======================
SELECT NVL(p.name, 'CDB$ROOT') AS container,
       COUNT(*)                AS cnt
FROM   cdb_services s
LEFT   JOIN v$pdbs p ON p.con_id = s.con_id
GROUP  BY NVL(p.name, 'CDB$ROOT')
ORDER  BY container;

PROMPT
PROMPT ============ ALL DEFINED SERVICES (ROOT + PDBs) + RUNNING ==============
SELECT NVL(p.name, 'CDB$ROOT')                            AS container,
       s.name                                             AS service_name,
       s.network_name,
       CASE WHEN a.name IS NOT NULL THEN 'YES' ELSE 'NO' END AS running
FROM   cdb_services s
LEFT   JOIN v$pdbs p          ON p.con_id = s.con_id
LEFT   JOIN v$active_services a ON a.name = s.name AND a.con_id = s.con_id
ORDER  BY s.con_id, s.name;

PROMPT
PROMPT (running = NO means the service is defined but not currently registered with the
PROMPT  listener -- expected for some internal services, investigate for app services.)
PROMPT
SET FEEDBACK ON
