# HANDOFF — RSQ_Meshturbator

## Done (measured)
- Nothing built yet. The rig (`rig/`) is the RS_ModelSwapper rig of 2026-11-09, engine unchanged; its
  `setup.sh` / `rig.py check` pass here (see the commit that says so).

## Not done
- Everything in `DESIGN.md`. First deliverable: the true pistol (DESIGN.md, last section).
- Blender → MD3 export of the sources in `assets/src/`. Blender is not in this workspace (no apt package,
  no bpy wheel for Python 3.13); the export is the owner's step or a Blender install here.

## Open
- Licence: the Colt M5 is CC Attribution by D_U (owner read the page, 03:53). The other six pages still to
  be read; assumed the same author and licence until then.
- Triangle budget: the M5 is 24.6k tris, above the 3-8k asked for. Judge on the rig / headset, then decide
  on a decimate pass.
- Fitting mode (DESIGN.md §5): how the hand marks a joint's two ends in the engine and how the numbers get
  into the data lump without a tool.
- The ammo gate (DESIGN.md §3) against mods that reload via inventory tokens, and dual-ammo weapons.
