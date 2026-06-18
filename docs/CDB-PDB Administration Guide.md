# CDB/PDB Administration Guide

A practical guide to operating Oracle Multitenant (CDB/PDB) databases on 12c/19c/21c,
and how the scripts in this repository support day-to-day administration. Written for a
DBA who manages consolidated databases and needs to do so safely and consistently.

> **Scope:** Oracle 12c / 18c / 19c / 21c multitenant. All names, paths, and values in
> examples are **placeholders / fictional**; nothing references any real or confidential
> environment.

---

## The multitenant model in one minute

A **Container Database (CDB)** holds:

- **CDB$ROOT** — the root container with Oracle-supplied metadata and common objects.
- **PDB$SEED** — a read-only template used to create new PDBs.
- **Pluggable Databases (PDBs)** — the application databases. Each looks and behaves like
  a self-contained database but shares the instance (SGA, background processes) with its
  siblings.

Consolidation is the point: many PDBs share one set of memory/processes, cutting overhead
while keeping applications isolated. Administration happens at two levels — **CDB-wide**
(from the root) and **per-PDB** (connected to the container).

---

## Connecting to the right container

- **To the root:** connect as a common user / `sqlplus / as sysdba`. `SHOW CON_NAME`
  confirms you are in `CDB$ROOT`.
- **To a PDB:** connect via the PDB's service (`...@host:port/<pdb_service>`), or from the
  root switch with `ALTER SESSION SET CONTAINER = <pdb_name>;`.
- **Where to run what:** CDB-wide reporting (the `CDB_*` views, `V$PDBS`) runs from the
  root; application/schema work runs inside the PDB. Every script in this repo notes which
  container to run it from (all are root-level here).

---

## Common vs local

| Concept | Common (root-wide) | Local (one PDB) |
|---|---|---|
| **Users** | `C##`-prefixed; exist in root + all PDBs | Application schemas; exist in one PDB |
| **Roles/privileges** | Apply across containers | Apply within the PDB |
| **Use** | CDB administration / monitoring | Application ownership and access |

`pdb_users.sql` distinguishes the two. Keep common users few and tightly privileged — a
common grant reaches every PDB.

---

## Daily / routine tasks (mapped to scripts)

| Task | Script |
|---|---|
| See which PDBs are open / will auto-open | `list_pdbs.sql` |
| Open PDBs left mounted after a restart | `open_all_pdbs.sql` |
| Make PDBs auto-open on restart (durable fix) | `save_pdb_state.sql` |
| Verify each PDB's connection services | `pdb_services.sql` |
| CDB-wide service topology audit | `cdb_services.sql` |
| Size / capacity per container | `pdb_size.sql`, `pdb_tablespaces.sql` |
| Review users (common vs local) | `pdb_users.sql` |
| Check parameter overrides per PDB | `cdb_parameters.sql` |
| Confirm undo mode (local vs shared) | `undo_configuration.sql` |

---

## The auto-open habit (most important operational point)

A PDB defaults to **MOUNTED** (closed) after a CDB restart. If you do not **save its open
state**, applications cannot connect until someone manually opens it — a recurring,
avoidable outage. The fix is one command:

```sql
ALTER PLUGGABLE DATABASE ALL OPEN;        -- open them now
ALTER PLUGGABLE DATABASE ALL SAVE STATE;  -- and auto-open them next restart
```

Make saving state part of provisioning every PDB. `list_pdbs.sql` shows at a glance which
PDBs lack a saved state; see **PDB Startup Procedure.md** for the full restart routine.

---

## Parameters in multitenant

Many parameters are **PDB-modifiable** — a PDB can override the root value with
`ALTER SYSTEM` while connected to that PDB. This is powerful (e.g., a reporting PDB using
a different `optimizer_mode`) but a frequent source of "why does this one PDB behave
differently?" `cdb_parameters.sql` shows which parameters are modifiable and compares a
parameter across all containers.

---

## Undo: local vs shared

From 12.2, **local undo** (each PDB has its own undo tablespace) is the default and is
required for PDB hot clone, relocate, and flashback PDB. `undo_configuration.sql` confirms
the mode and that each container has an undo tablespace. Prefer local undo unless you have
a specific reason for shared.

---

## Lifecycle operations (overview)

These are beyond the read-only scripts here but are core multitenant skills:

- **Create** a PDB from the seed: `CREATE PLUGGABLE DATABASE <pdb> ADMIN USER ...`.
- **Clone** a PDB (hot clone with local undo) for test/QA refreshes.
- **Plug/unplug** to move a PDB between CDBs (unplug to an XML manifest, plug elsewhere).
- **Relocate** a PDB to another CDB with minimal downtime (`... RELOCATE`).
- **Resource Manager** to cap CPU/parallel/memory per PDB so one container cannot starve
  the others — important once PDBs differ in load (see `pdb_size.sql`).

Always back up and verify before lifecycle operations, and confirm services and saved
state afterward.

See **Multitenant Troubleshooting.md** for common problems and **PDB Startup
Procedure.md** for the restart routine.
