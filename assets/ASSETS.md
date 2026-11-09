# assets/src — mesh sources, as downloaded

All seven from the same Sketchfab author (owner, 2026-11-09): **D_U**, https://sketchfab.com/D_U .
`low-poly-colt-m5-scw` is https://sketchfab.com/3d-models/low-poly-colt-m5-scw-dd2582bed94348e39c377438cc9396bc —
**Licence: CC Attribution** (read off the model page by the owner, 2026-11-09 03:53; 24.6k triangles, 12.2k
vertices, published 2026-08). Attribution to ship with the pack: "Weapon meshes by D_U (sketchfab.com/D_U),
CC BY 4.0". The other six are the same author; their pages still to be read for licence and counts.

24.6k triangles is above the 3-8k this project asked for (Quest draws every part as its own HUD model). To
be judged on the rig and in the headset before deciding on a decimate pass in Blender.

No textures in any of them except the G36 and MP7 (two/one JPEGs); the rest are material colours (steel,
polymer, brass, copper, polycarbonate), to be baked to one small palette texture at export.

| folder | source | Blender | reload parts (separate, named) |
|---|---|---|---|
| colt-m5-scw | m5 scw.blend + low-poly_colt_m5_scw.glb (Sketchfab converted; the one the pack is built from) | 3.6 | PMAG 30rnd full + empty, 5.56 round, spent case, bolt, charging handle, dust cover, bolt catch L/R, mag catch L/R, selector, trigger; body: upper, lower, grip, stock, handguard, 10.3in barrel, flash hider, iron sights; m4a1 upper/selector variant |
| hk-g36 | hk g36.blend | 3.6 | G36 30rnd mag full + empty, 5.56 round, bolt carrier, bolt head, bolt catch, charging handle, mag release, selector, trigger; body: upper/lower receiver, barrel, flash hider, handguard, stock, carry handle, red dot |
| hk-mp7-a1 | hk mp7.blend | 3.6 | MP7 30rnd mag full + empty, 4.6x30 round, bolt carrier, bolt release, charging handle, selector, trigger; body: receiver, 7in barrel, flash hider, suppressor, folding foregrip, sights, stock |
| desert-eagle-xix | desert eagle.blend | 3.6 | 7rnd mag full + empty, .50AE round, spent case, slide, slide release, hammer, safety, trigger; body: frame, barrel |
| benelli-m4 | benelli m4.blend | 3.6 | 12/70 shell + spent hull, bolt, carrier, safety, trigger; body: receiver, 18.5in barrel, handguard, stock (semi-auto: no pump) |
| dsa-sa58-graywolf | DSA GRAYWOLF.blend | 3.0 | two objects only: GRAYWOLF (whole rifle) and SCOPE — fused, no parts; usable as a no-reload mesh or needs splitting |
| noreen-bn36 | Noreen BN36.fbx | FBX | not inspected (FBX binary) |

Archetype map (DESIGN.md §1): pistol = Desert Eagle; SMG = MP7; rifle = M5 / G36; shotgun (semi-auto) =
Benelli M4. Still wanted: pump shotgun, double-barrel, revolver (the author has a CC-BY Colt Python with
speedloader), launcher, plasma, chainsaw, fists.

## The .glb is the working source
Sketchfab's converted `.glb` keeps every object as a named node with its transform and the licence in its
metadata, and needs no Blender: `glb2obj.py` (kept outside the repo) writes one OBJ per object. The `.blend`
is the author's original and stays here as such. For the other six meshes: download the `.glb`.
