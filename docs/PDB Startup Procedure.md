# PDB Startup Procedure

The routine for bringing a multitenant database fully online after a CDB restart, and for
guaranteeing PDBs auto-open in future. The recurring "CDB is up but the PDB is closed"
outage is entirely preventable — this procedure prevents it.

> **Scope:** Oracle 12c / 18c / 19c / 21c multitenant. Placeholders/fictional names
> throughout; nothing references any real or confidential environment.

---

## Why PDBs don't open by themselves

When a CDB starts, the instance and `CDB$ROOT` open, but each **PDB defaults to MOUNTED**
(closed). A PDB opens automatically **only if its open state was saved** (or a startup
trigger opens it). If neither is in place, applications connecting to that PDB fail until
a DBA opens it manually — which is the outage to avoid.

---

## Standard startup sequence (after a CDB restart)

### 1. Confirm the CDB instance is open

```sql
sqlplus / as sysdba
SQL> SELECT status FROM v$instance;        -- OPEN
SQL> SHOW CON_NAME;                          -- CDB$ROOT
```

### 2. Check PDB state

Run `list_pdbs.sql`. Note any PDB showing `MOUNTED` and/or `SAVED_STATE = NONE` — those
are the ones that did not auto-open (or won't next time).

### 3. Open the PDBs

Open everything that should be open:

```sql
ALTER PLUGGABLE DATABASE ALL OPEN;
```
Variants:
```sql
ALTER PLUGGABLE DATABASE <pdb> OPEN;                 -- one PDB
ALTER PLUGGABLE DATABASE ALL EXCEPT MAINT_PDB OPEN;  -- hold one back
ALTER PLUGGABLE DATABASE <pdb> OPEN READ ONLY;       -- e.g., a reporting PDB
```
(`open_all_pdbs.sql` does this with before/after verification.)

### 4. Save the open state (so this is automatic next time)

```sql
ALTER PLUGGABLE DATABASE ALL SAVE STATE;
```
After this, the saved PDBs auto-open with the CDB and step 3 is no longer needed on
restart. (`save_pdb_state.sql` does this with verification.) Confirm:
```sql
SELECT con_id, con_name, state FROM dba_pdb_saved_states ORDER BY con_id;
```

### 5. Verify services are registered

Run `pdb_services.sql` / `cdb_services.sql`. Each PDB's application service should be
present and registered with the listener; start any that are missing:
```sql
ALTER SESSION SET CONTAINER = <pdb>;
EXEC DBMS_SERVICE.START_SERVICE('<svc>');
```

### 6. Functional check

- `list_pdbs.sql` — all intended PDBs `READ WRITE` (or the intended mode), none
  unexpectedly `RESTRICTED`.
- Application/owner confirms connectivity to each PDB.

---

## Controlling open mode per PDB

Different PDBs may need different modes — e.g., a reporting PDB opened READ ONLY, a
maintenance PDB held closed. Open each in the intended mode **before** saving state, so
the saved state captures exactly what you want on restart.

```sql
ALTER PLUGGABLE DATABASE SALES_PDB OPEN READ WRITE;
ALTER PLUGGABLE DATABASE RPT_PDB   OPEN READ ONLY;
ALTER PLUGGABLE DATABASE SALES_PDB SAVE STATE;
ALTER PLUGGABLE DATABASE RPT_PDB   SAVE STATE;
```

---

## Alternative: startup trigger (legacy / special cases)

Saved state is the modern, preferred mechanism. A system startup trigger that issues
`ALTER PLUGGABLE DATABASE ALL OPEN` is an older alternative still seen in the field — use
it only where saved state isn't suitable, and don't run both mechanisms in conflict.

---

## RAC and Data Guard notes

- **RAC:** save state is per-instance; ensure PDBs open on the intended instances and
  services are managed via `srvctl`.
- **Data Guard:** on a physical standby the PDB open behavior follows the standby's role;
  manage open mode in line with the standby/primary role (see the patching repo's Data
  Guard sequence for related role handling).

---

## The one rule to remember

**Open the PDBs in the mode you want, then SAVE STATE.** Doing this at provisioning time
makes every future restart a non-event — the difference between a clean reboot and a 2am
"the application is down" call. See **Multitenant Troubleshooting.md** for what to do when
a PDB still won't open cleanly.
