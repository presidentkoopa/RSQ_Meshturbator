# HANDOFF — RSQ_Meshturbator (written 2026-11-09, end of the first session; the owner stopped here)

## Done (measured)
- **The part system runs and draws** (rig only, not headset-confirmed). On doom2 + the pack, zero script
  errors. The M5 (D_U's mesh from the Sketchfab .glb) is drawn at the gun controller with body, magazine,
  bolt and charging handle as separate parts. The magazine cycle ran end to end, driven by posed controllers,
  and the frames show it (`rig/mt_test.py mag`): grab in the well -> pulled out, in the hand -> let go, falls
  to the floor as a world object -> fresh one from the pouch (hand at the hip) -> caught by the well -> pushed
  home, seated. Log: `MT t121 grabbed mag ... t150 out, in the hand ... t162 dropped (30 rounds) ... t212
  fresh magazine from the pouch ... t225 caught by the well at 12.0 cm ... t254 seated (30 rounds)`.
- **Mesh pipeline without Blender.** Sketchfab's converted `.glb` carries every object as a named node with
  its transform and the licence in its metadata. `glb2obj.py` (kept OUTSIDE the repo; a copy is at
  `/home/claude/meshes/glb2obj.py` on the session machine and must be re-made if lost -- it is ~200 lines)
  writes one OBJ per object in GZDoom OBJ space (x forward, y up, z right; the loader negates z,
  `models_obj.cpp RealignVector`). Scale read off the mesh: D_U's 5.56x45 case is 0.447 units = 44.7 mm real,
  so 1 unit = 10 cm (the 10.3in barrel object is 26.9 cm). Origin = the grip's bounding-box centre. MTARCH m5
  numbers are the parts' bounding boxes in that frame (listed in the lump with their source).
- Licence of the M5: in the .glb metadata, `D_U (https://sketchfab.com/DU1701)`, `CC-BY-4.0`.
- `pk3/RSQ_Meshturbator.pk3` is the build of a883486: loads clean, `give MT_M5`, grab = off-hand trigger
  (`mt_grab 1` = grip), `mt_debug 1` prints every state change, `netevent mt_state` dumps the gun.

## The decision that stopped the session: the LOOK
- D_U's models have **no textures**: six flat material colours. Sketchfab's live PBR lighting makes them look
  like guns; Doom lights a HUD model flat (sector light, no per-face shading), so they render as silhouettes.
- A bake of the viewer's lighting into a texture per part was tried (`glb2obj.py --bake`, commit a883486):
  the rails, slots, witness stripe and grip texture read, tone a shade light/cool. The owner rejected baking as
  the route ("don't invent textures"; and not for 300 models, even automated). **Baking is off the table.**
- BD22's own textured meshes as the library: **rejected** by the owner (that was ModelSwapper's approach).
- **Chosen direction, not started:** textured community models with separate parts. Six CC-BY candidates
  were found (Sketchfab; all with real Substance/PBR textures):
  - Pistol 9mm semi-auto (G19), Hitansh 3D -- 18k tris, 4K PBR, "all major parts separate"
    https://sketchfab.com/3d-models/pistol-9mm-semi-auto-7d363c3cf2f74a9a9fb0cab9874898eb
  - AK-47, Beerus -- 4K PBR, "separate parts (trigger, magazine, bolt)"
    https://sketchfab.com/3d-models/ak-47-492ca153f57144b996553a83ef6fde09
  - HK 416 Low Poly, Derek Flanagan -- 3.8k tris, 4K PBR; part separation unverified
    https://sketchfab.com/3d-models/hk-416-assault-rifle-low-poly-fbdf159836224d67b193ca527d4f4333
  - Revolver - Separate Parts, Miguel Adao -- 6.8k tris, Substance textures, separate parts
    https://sketchfab.com/3d-models/revolver-separate-parts-d14f9b5409c143dd801a9260708bd419
  - Revolver (vintage), Mik Santos -- 18.6k tris, "per part pivots"
    https://sketchfab.com/3d-models/revolver-6e62a5c020024d47aac3782910e40d13
  - Shotgun game ready, grigorijorlinskij -- 3.5k tris, Substance; pump separation unverified
    https://sketchfab.com/3d-models/shotgun-game-ready-4e7f3359f8d946289a61312879a5fb70
  Check on each page: the layers icon lists the parts (mag / slide / cylinder as their own entries), and the
  download box says textures are images, not "Material". Download `.glb` (textures are embedded).
  The one code change needed on this side: `glb2obj.py` must write the embedded textures out and carry the
  mesh's own UVs (today it writes `vt 0 0` and a flat-colour PNG per material).

## Not done
- Charging handle pull / bolt lock / fire / eject: code written and loads clean, NOT driven or shown in frames.
- The gun's placement in the hand (grip at a bounding-box centre, not a fit), the well's tilt, the hold point
  of a carried mag, the eject direction: all await the fitting mode (DESIGN.md §5), which does not exist.
- A hand mesh: the off hand is a pink box. (Ermac's hands are licensed for education only -- not usable.)
- The universal attach (DESIGN.md §3, the Ammo1 gate): not written. MT_M5 is layer 2 only.
- Quest performance: the M5 body alone is 16k triangles on one HUD layer.
- The other six D_U meshes (.blend only, no .glb downloaded) -- moot if the direction above holds.

## Open / lessons from this session (so they are not repeated)
- The "layers not drawn" scare was mine: placeholder boxes written in MD3 axes (x fwd, y left, z up) where
  GZDoom OBJ wants (x fwd, y up, z right), plus a head pose looking at the ceiling. The engine draws
  item-owned model layers exactly as the teardown's `11_HUD_MODELS.md` says. READ THE TEARDOWN FIRST:
  `/home/claude/presidentkoopa/rsq_questenginesurvey/surveys/`.
- Never send the owner a frame without looking at it as he will: the grey M5 went out un-flagged.
- Known rig limit (from ModelSwapper): a posed controller's ROLL does not reach ZScript.
- Rig frame files are numbered by render frame, not by tic (the headless renderer runs slower than 35 Hz).
