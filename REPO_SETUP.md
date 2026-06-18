# Repository Setup Guide (publishing checklist)

> For you, Usen — NOT portfolio content. After you set the GitHub topics and confirm
> everything looks right, delete it (or keep it private). It explains where every file
> belongs, the topics to add, the screenshots to capture, and how to publish
> `oracle-cdb-pdb-administration`.

---

## 1. Where every file belongs

```
oracle-cdb-pdb-administration/               <- repository root
├── README.md                                <- main landing page
├── LICENSE                                   <- MIT license (GitHub auto-detects at root)
├── .gitignore                               <- keeps logs, manifests, credentials out
├── REPO_SETUP.md                             <- THIS file (delete before/after publishing)
│
├── scripts/                                  <- 10 read-only CDB/PDB scripts (run from root)
│   ├── list_pdbs.sql
│   ├── open_all_pdbs.sql
│   ├── save_pdb_state.sql
│   ├── pdb_services.sql
│   ├── cdb_services.sql
│   ├── pdb_size.sql
│   ├── pdb_tablespaces.sql
│   ├── pdb_users.sql
│   ├── cdb_parameters.sql
│   └── undo_configuration.sql
│
├── sample_outputs/                           <- one fictional, sanitized sample per script
│   ├── list_pdbs_sample.txt
│   ├── open_all_pdbs_sample.txt
│   ├── save_pdb_state_sample.txt
│   ├── pdb_services_sample.txt
│   ├── cdb_services_sample.txt
│   ├── pdb_size_sample.txt
│   ├── pdb_tablespaces_sample.txt
│   ├── pdb_users_sample.txt
│   ├── cdb_parameters_sample.txt
│   └── undo_configuration_sample.txt
│
├── docs/
│   ├── CDB-PDB Administration Guide.md
│   ├── Multitenant Troubleshooting.md
│   └── PDB Startup Procedure.md
│
└── screenshots/
    └── README.md
```

Rationale: `README.md` and `LICENSE` at the root for GitHub; scripts under `scripts/`;
fictional results under `sample_outputs/`; markdown docs render on GitHub.

> Note: the admin-guide file is named `CDB-PDB Administration Guide.md` (hyphen, not
> slash) because `/` is not a legal filename character. The README links to it correctly.

---

## 2. GitHub topics (add via the ⚙️ next to "About")

```
oracle
oracle-database
multitenant
cdb
pdb
pluggable-database
container-database
dba
database-administration
oracle-19c
oracle-21c
oracle-12c
database-engineering
consolidation
```

Suggested **About** description:
> *Read-only SQL scripts and guides for administering Oracle Multitenant (CDB/PDB) on
> 12c–21c — PDB state, services, sizing, users, parameters, undo. Sanitized.*

---

## 3. Screenshots to capture (optional, high-impact)

From a lab CDB, sanitized, dark terminal. Priority order:

1. `list_pdbs.png` — PDB inventory (open mode + saved state)
2. `save_pdb_state.png` — before/after saved states
3. `pdb_tablespaces.png` — per-PDB space with an ALERT row
4. `cdb_parameters.png` — a parameter overridden in one PDB
5. `undo_configuration.png` — local undo confirmed

See `screenshots/README.md`. The list_pdbs + save_pdb_state pair tells the story in two.

---

## 4. Publishing steps

```bash
cd oracle-cdb-pdb-administration
git init
git add .
git commit -m "Oracle CDB/PDB administration scripts, samples, and docs (12c-21c)"
git branch -M main
git remote add origin https://github.com/uusen01/oracle-cdb-pdb-administration.git
git push -u origin main
```

Then on github.com/uusen01/oracle-cdb-pdb-administration:
1. Add the **topics** from section 2 and set the **About** description.
2. Confirm `LICENSE` shows "MIT" in the sidebar.
3. (Optional) add screenshots and link them in the README.
4. **Pin** the repo on your profile.
5. Ensure the profile README "Featured" link points here as a clickable markdown link.

---

## 5. Final sanitization pass before pushing

- [ ] No real hostnames, IPs, SIDs, service names, or DBIDs (placeholders only;
      `ORADEMO`, `SALES_PDB`, `RPT_PDB`, `MAINT_PDB` and sample values are fictional).
- [ ] No credentials; no `tnsnames.ora`/`login.sql` committed (.gitignore covers these).
- [ ] No PDB unplug manifests (`*.xml`) or datafiles committed (.gitignore covers these).
- [ ] No USPS / AT&T / GM / employer identifiers in any file.
- [ ] Sample outputs are clearly fictional and labeled in the README disclaimer.
- [ ] Delete this `REPO_SETUP.md` if you don't want it public.

---

## Note — this is your strongest hands-on area

Per the Master Experience Document, your current USPS role is **Oracle 21c CDB/PDB on
Windows**, and the PDB SAVE STATE fix (eliminating recurring post-restart outages) is one
of your real STAR stories. This repo mirrors that work directly — the `save_pdb_state.sql`
+ `list_pdbs.sql` + PDB Startup Procedure trio is exactly that incident, generalized and
sanitized. It is the most defensible repo in your portfolio for the interview.
