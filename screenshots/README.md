# Screenshots

Optional terminal captures used in the main README and for portfolio presentation.
Images are not required for the scripts to work — they exist to show recruiters and hiring
managers real multitenant administration at a glance.

## Capture guidance

- Run each script from `CDB$ROOT` on a **non-production / lab** multitenant database and
  capture the output in a clean terminal (dark theme, monospaced font, no wrapping).
- **Sanitize before capturing.** Confirm no real hostnames, IPs, service names,
  schema/user names, or company identifiers appear. Use generic container names (e.g.,
  `ORADEMO`, `SALES_PDB`, `RPT_PDB`) as in `sample_outputs/`.
- Save as PNG named to match the script, e.g. `list_pdbs.png`, `save_pdb_state.png`.

## Recommended screenshots (highest portfolio signal first)

1. **`list_pdbs.png`** — the PDB inventory with open mode + saved state, ideally showing
   one PDB MOUNTED / NONE. Instantly readable to any Oracle interviewer.
2. **`save_pdb_state.png`** — before/after saved states. Demonstrates you know the fix to
   the #1 multitenant outage (PDB not auto-opening).
3. **`pdb_tablespaces.png`** — per-PDB space with an ALERT row; shows container-aware
   monitoring.
4. **`cdb_parameters.png`** — a parameter overridden in one PDB; shows deep multitenant
   understanding.
5. **`undo_configuration.png`** — local undo confirmed per container.

Five well-chosen, sanitized screenshots beat capturing all ten. The `list_pdbs` +
`save_pdb_state` pair tells a complete operational story in two images.
