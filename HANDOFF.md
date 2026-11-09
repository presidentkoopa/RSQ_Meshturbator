# HANDOFF — RSQ_Meshturbator

## Done (measured)
- **The part system runs and draws** (rig only, not headset-confirmed; 2026-11-09 04:50). On doom2 + the pack,
  zero script errors. The M5 (D_U's mesh, converted from the Sketchfab .glb) is drawn at the gun controller
  with magazine, bolt and charging handle as separate parts. The magazine cycle ran end to end, driven by
  posed controllers, and the frames show it (`rig/mt_test.py mag`): grab in the well -> pulled out, in the
  hand -> let go, falls to the floor as a world object -> fresh one from the pouch (hand at the hip) ->
  caught by the well -> pushed home, seated. Log: `MT t121 grabbed mag ... t150 out, in the hand ... t162
  dropped (30 rounds) ... t212 fresh magazine from the pouch ... t225 caught by the well at 12.0 cm ... t254
  seated (30 rounds)`.
- **Mesh pipeline without Blender**: Sketchfab's converted `.glb` carries every object as a named node with
  its transform; `glb2obj.py` (NOT in the repo: tools stay out) writes one OBJ per object in GZDoom OBJ space
  (x forward, y up, z right; the loader negates z — `models_obj.cpp RealignVector`). Scale is read off the
  mesh: D_U's 5.56x45 case is 0.447 units = 44.7 mm real, so 1 unit = 10 cm; the barrel object is 26.9 cm
  for a 10.3in barrel. Origin = the grip's bounding-box centre. MTARCH m5 numbers are the parts' bounding
  boxes in that frame (listed in the lump).
- The licence is in the .glb's own metadata: `author D_U (https://sketchfab.com/DU1701)`, `CC-BY-4.0`.

- **The look (04:45).** The glb has no textures: six material colours, and Sketchfab's live lighting did the
  rest. Doom lights a model flat, so that lighting is baked once into a texture per part from the mesh's own
  normals (glb2obj.py --bake: key/fill/rim + a specular term, a cell per triangle, the author's colours lifted
  from 1% grey to the mid-grey the viewer shows). Nothing painted, nothing invented. Frame: rails, handguard
  slots, witness stripe, grip texture read. Tone is a shade lighter and cooler than the Sketchfab render.

## Not done
- The charging handle pull / bolt lock / fire / eject paths: code written, ran without error in the `load`
  run, NOT yet driven or shown in frames.
- The gun's placement in the hand (grip at the controller is a bounding-box centre, not a fit), the well's
  tilt, the hold point of a carried mag: all awaiting the fitting mode (DESIGN.md §5), which does not exist.
- A hand mesh: the off hand is a pink box.
- The six other D_U meshes: `.glb` downloads needed (the `.blend` sources are useless without Blender).
- Quest performance: the M5 body alone is 16k triangles on one HUD layer.

## Open
- `IsHUDModelForPlayerAvailable` / the 3 a.m. "layer not drawn" observations: with the real mesh and the camera
  actually pointed at the hands, every layer draws. The earlier non-draws were my placeholder boxes written
  in MD3 axes (x fwd, y left, z up) where GZDoom OBJ wants (x fwd, y up, z right), and a head pose looking
  away. No engine rule involved; 11_HUD_MODELS.md stands as written.
- Known rig limit (from ModelSwapper): a posed controller's ROLL does not reach ZScript.
