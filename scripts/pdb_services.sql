--------------------------------------------------------------------------------
-- Script:        pdb_services.sql
-- Purpose:       List the database services associated with each PDB so a DBA can
--                confirm applications have the right connection service, and spot
--                missing or extra services after a clone/relocate.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on CDB_SERVICES / V$SERVICES, V$PDBS (or SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @pdb_services.sql
--
-- Explanation:
--   * Each PDB automatically has a default service matching its name; applications use
--     that service (or a custom one) to connect directly to the PDB rather than the root.
--   * After cloning, plugging, or relocating a PDB, services can be missing or duplicated
--     -- this script surfaces the actual service-to-PDB mapping so connectivity issues
--     are easy to diagnose.
--   * V$SERVICES shows services currently registered with the listener (live); CDB_SERVICES
--     shows the defined services per container.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. Service/PDB names
--                are resolved at runtime.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN pdb_name      FORMAT A22
COLUMN service_name  FORMAT A34
COLUMN network_name  FORMAT A34
COLUMN open_mode     FORMAT A12

PROMPT
PROMPT ================= DEFINED SERVICES BY PDB (CDB_SERVICES) ===============
SELECT p.name              AS pdb_name,
       s.name              AS service_name,
       s.network_name,
       p.open_mode
FROM   cdb_services s
JOIN   v$pdbs p ON p.con_id = s.con_id
WHERE  s.name NOT LIKE 'SYS%'         -- hide internal services
ORDER  BY p.con_id, s.name;

PROMPT
PROMPT ============= SERVICES CURRENTLY REGISTERED (V$SERVICES) ==============
SELECT con_id,
       name AS service_name,
       network_name
FROM   v$services
WHERE  con_id > 2                      -- skip root/seed
ORDER  BY con_id, name;

PROMPT
PROMPT (A PDB with no application service registered cannot be reached by its apps even
PROMPT  when OPEN -- check here if connections fail after a clone/relocate.)
PROMPT
SET FEEDBACK ON
