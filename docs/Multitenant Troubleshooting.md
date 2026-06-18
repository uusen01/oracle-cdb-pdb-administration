# Multitenant Troubleshooting

The problems most often seen administering Oracle CDB/PDB databases, the script in this
repository that surfaces each, the root cause, and the fix. Commands are templates —
adapt names and apply under change control.

> All examples use placeholders/fictional data. Nothing references any real or
> confidential environment.

---

## 1. PDB not open after a CDB restart (apps can't connect)

**Detected by:** `list_pdbs.sql` (PDB shows `MOUNTED`, `SAVED_STATE = NONE`).
**Cause:** PDBs default to MOUNTED on CDB startup; without a saved open state they stay
closed and applications fail to connect.

**Fix (immediate + durable):**
```sql
ALTER PLUGGABLE DATABASE ALL OPEN;        -- restore service now
ALTER PLUGGABLE DATABASE ALL SAVE STATE;  -- auto-open on future restarts
```
This is the single most common multitenant incident. Saving state at provisioning time
prevents it. See `open_all_pdbs.sql` / `save_pdb_state.sql`.

---

## 2. Application can connect to the CDB but not its PDB

**Detected by:** `pdb_services.sql`, `cdb_services.sql` (expected service missing/not
registered).
**Cause:** the PDB's service is not registered with the listener — often after a clone,
plug, or relocate, or because the PDB is closed.

**Fix:**
- Confirm the PDB is OPEN (`list_pdbs.sql`).
- Confirm the service exists and is registered; create one if needed:
  ```sql
  EXEC DBMS_SERVICE.CREATE_SERVICE('<svc>','<svc>');   -- inside the PDB
  EXEC DBMS_SERVICE.START_SERVICE('<svc>');
  ```
- Re-check listener registration (`lsnrctl status`).

---

## 3. ORA-65096 / common user naming error

**Symptom:** `CREATE USER` in the root fails with "invalid common user or role name."
**Cause:** common users (created in the root) must start with the prefix `C##` (or the
configured `COMMON_USER_PREFIX`); a local-style name is rejected in the root.

**Fix:** name common users `C##NAME`, or create the account **inside the target PDB** as a
local user instead:
```sql
ALTER SESSION SET CONTAINER = <pdb>;
CREATE USER app_owner IDENTIFIED BY ... ;   -- local user, no C## needed
```

---

## 4. ORA-65040 / operating on the wrong container

**Symptom:** an operation fails because it is "not allowed from within a pluggable
database," or a change you made "didn't take" anywhere.
**Cause:** running a command in the wrong container — e.g., a CDB-level change attempted
from a PDB, or a PDB change attempted from the root.

**Fix:** confirm your container before acting:
```sql
SHOW CON_NAME;
ALTER SESSION SET CONTAINER = CDB$ROOT;   -- or the specific PDB
```

---

## 5. A single PDB behaves differently from its siblings

**Detected by:** `cdb_parameters.sql` (a parameter differs for one container).
**Cause:** that PDB has overridden a PDB-modifiable parameter (e.g., `optimizer_mode`,
memory settings) locally.

**Fix:** decide whether the override is intentional. To revert to the CDB default:
```sql
ALTER SESSION SET CONTAINER = <pdb>;
ALTER SYSTEM RESET <parameter> SCOPE=BOTH;
```

---

## 6. Space error inside one PDB (ORA-01653) not visible from the root summary

**Detected by:** `pdb_tablespaces.sql` (a PDB tablespace flagged `ALERT`).
**Cause:** a tablespace inside a specific PDB is near its autoextend ceiling even though
the CDB overall looks fine.

**Fix (inside the PDB):**
```sql
ALTER SESSION SET CONTAINER = <pdb>;
ALTER TABLESPACE <ts> ADD DATAFILE '...' SIZE 10G AUTOEXTEND ON MAXSIZE 64G;
```

---

## 7. PDB clone/relocate fails or flashback PDB unavailable

**Detected by:** `undo_configuration.sql` (`LOCAL_UNDO_ENABLED = FALSE`).
**Cause:** hot clone, relocate, and flashback PDB require **local undo**; with shared undo
they are restricted or unavailable.

**Fix:** enable local undo (requires a restart in upgrade mode):
```sql
-- High level: STARTUP UPGRADE; ALTER DATABASE LOCAL UNDO ON; restart normally.
```
Each PDB then gets its own undo tablespace automatically.

---

## 8. PDB stuck in RESTRICTED mode

**Detected by:** `list_pdbs.sql` (`RESTRICTED = YES`).
**Cause:** the PDB opened with a warning/violation (e.g., a plug-in compatibility issue,
missing datafile, or parameter mismatch) so Oracle opened it RESTRICTED.

**Fix:** review the cause:
```sql
ALTER SESSION SET CONTAINER = <pdb>;
SELECT name, cause, type, message, status FROM pdb_plug_in_violations;
```
Resolve the reported violations, then close and reopen the PDB normally.

---

## General method

1. **Know your container** (`SHOW CON_NAME`) before running anything.
2. **Use the root's `CDB_*`/`V$PDBS` views** to see all containers at once; drill into a
   PDB only when needed.
3. **Saved state + services** are the two things to verify after any restart, clone, or
   relocate — they cause most "can't connect" incidents.

See **CDB/PDB Administration Guide.md** for the operating model and **PDB Startup
Procedure.md** for the restart routine.
