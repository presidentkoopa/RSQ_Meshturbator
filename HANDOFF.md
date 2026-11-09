# HANDOFF — RSQ_Meshturbator

## Done (measured)
- Nothing built yet. The rig (`rig/`) is the RS_ModelSwapper rig of 2026-11-09, engine unchanged; its
  `setup.sh` / `rig.py check` pass here (see the commit that says so).

## Not done
- Everything in `DESIGN.md`. First deliverable: the true pistol (DESIGN.md, last section).
- Blender → MD3 export of the sources in `assets/src/`. Blender is not in this workspace (no apt package,
  no bpy wheel for Python 3.13); the export is the owner's step or a Blender install here.

## Open
- Licence of the seven Sketchfab sources: author appears to be `notcplkerry` (naming matches their
  "Low-Poly AR-15 magazines"); their models seen so far are CC Attribution. To confirm on each model page.
- Fitting mode (DESIGN.md §5): how the hand marks a joint's two ends in the engine and how the numbers get
  into the data lump without a tool.
- The ammo gate (DESIGN.md §3) against mods that reload via inventory tokens, and dual-ammo weapons.
