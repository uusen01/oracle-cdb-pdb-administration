--------------------------------------------------------------------------------
-- Script:        pdb_users.sql
-- Purpose:       Distinguish COMMON users (exist in the root and every PDB) from LOCAL
--                users (exist only in one PDB), and surface their account status, for
--                security review and to understand the multitenant user model.
-- Compatibility: Oracle 12c, 18c, 19c, 21c multitenant (CDB). Run from CDB$ROOT.
-- Privileges:    SELECT on CDB_USERS, V$PDBS (or SELECT_CATALOG_ROLE).
--
-- Example execution:
--   sqlplus / as sysdba
--   SQL> @pdb_users.sql
--
-- Explanation:
--   * COMMON users (COMMON='YES', typically C##-prefixed for user-created ones) are
--     defined once in the root and visible in all containers -- used for CDB-wide
--     administration. LOCAL users (COMMON='NO') exist only inside a single PDB and own
--     the application schemas.
--   * Reviewing this matters for security: a common user with broad privileges affects
--     every PDB, so common accounts should be few and tightly controlled.
--   * Section 2 flags OPEN (non-system) accounts and lock status per PDB -- useful for
--     spotting unlocked default or stale accounts during a security pass.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. User/PDB names
--                are resolved at runtime.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN pdb_name   FORMAT A20
COLUMN username   FORMAT A26
COLUMN common     FORMAT A7
COLUMN account_status FORMAT A18
COLUMN scope      FORMAT A8
COLUMN cnt        FORMAT 999,990

PROMPT
PROMPT ============== USER COUNT BY CONTAINER AND SCOPE ======================
SELECT p.name              AS pdb_name,
       CASE WHEN u.common = 'YES' THEN 'COMMON' ELSE 'LOCAL' END AS scope,
       COUNT(*)            AS cnt
FROM   cdb_users u
JOIN   v$pdbs p ON p.con_id = u.con_id
GROUP  BY p.name, CASE WHEN u.common = 'YES' THEN 'COMMON' ELSE 'LOCAL' END
ORDER  BY p.name, scope;

PROMPT
PROMPT ========= LOCAL APPLICATION ACCOUNTS BY PDB (NON-ORACLE-MAINTAINED) =========
SELECT p.name           AS pdb_name,
       u.username,
       u.common,
       u.account_status
FROM   cdb_users u
JOIN   v$pdbs p ON p.con_id = u.con_id
WHERE  u.oracle_maintained = 'N'      -- exclude Oracle-supplied accounts
ORDER  BY p.name, u.username;

PROMPT
SET FEEDBACK ON
