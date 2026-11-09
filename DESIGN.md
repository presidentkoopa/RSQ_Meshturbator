# The system (as decided with the owner, 2026-11-09 03:35–03:45)

Five pieces. The first three make it universal; the last two make it VR. Nothing here is built yet.

## 1. The mesh library is ours, not the mod's
One mesh per archetype — pistol, SMG, rifle, pump shotgun, double-barrel, revolver, rocket launcher,
plasma/energy, chainsaw, fists/melee (minigun and BFG are "no reload, just a mesh"). A mod's weapon is
attached to THAT mesh. The measurement count is fixed at the size of the library, forever.

Sources are low-poly assets with separate, named objects (`assets/src/`). Because our joints move the parts,
a mesh needs **no animation**: a gun is a set of static objects. Export: Blender -> one MD3 per gun, one
surface per object, names kept, grip at the origin, material colours baked to one small palette texture
(MD3 is one skin per surface; PBR does not survive and QuestZDoom would not use it).

## 2. A weapon is parts and joints
- **A part is an object.** Its own MD3 surface, its own HUD layer, its own state: where it is, what it is
  attached to (gun / hand / world), what is in it. A magazine knows how many rounds it holds. A shell is a
  shell. A cylinder has six chambers, each empty, loaded or fired. Nothing is a count on the weapon
  pretending to be a thing.
- **A joint is a constraint, not an animation.** The hand moves the part; the joint says what motion is
  allowed: *slide* along an axis between seated and free (magazine, slide, pump, charging handle, bolt);
  *hinge* about an axis between closed and open (break action, swing-out cylinder, loading gate); *free*
  (shells, rounds, a dropped magazine). Detents at the ends — the mag clicks home, the action locks open,
  the cylinder latches — and those detents are the events everything else hangs off.
- **The gun has real mechanical state.** Chambered or not. Slide forward or locked back. Action open or
  closed. Hammer back. Fire with the mag out and a round chambered: it fires once. Rack with a full mag: a
  live round ejects. Insert on a locked slide: it stays locked until released or racked. Pump before the
  shell is seated: nothing. These fall out of the state model; none is a special case.
- **Dropped parts are real.** A released magazine becomes a world actor with gravity, lands, and can be
  picked back up with its rounds still in it. Shells on the floor are shells.

## 3. The universal attach is the ammo gate
The one thing every Doom weapon has is `Ammo1`. We own the magazine: the weapon's `Ammo1` is set to our
chamber + magazine count every tic; the rest of the player's ammo sits in a hidden reserve. The mod's fire
code sees an empty gun when we are empty and never knows why; seating a mag moves rounds from reserve into
`Ammo1`. No Reload-state parsing, no tokens, no per-mod profiles. Mods with their own magazine systems
(Brutal Doom, Project Brutality) get their Reload state blanked: one line per such mod, the only per-mod
data there is. Known risks to watch: mods that reload via inventory tokens instead of `Ammo1`; dual-ammo
weapons.

## 4. Hands by hand
The hand does one thing: grab. Off hand within a part's grab radius + grip takes the part; the part rides
the hand in full 6DOF; when it enters a joint's capture zone the joint takes over and projects the hand's
motion onto the allowed path; release lets go wherever it is. One interaction, every weapon.
Main hand: the gun mesh only. Off hand: a fist, which becomes the holding hand while a part is in it.

## 5. Measurement is done in VR, in the rig, once per library mesh
A fitting mode in the pack: hold the gun, grab the magazine, pull it out — the engine records where it was
seated and where it came free, and that difference IS the axis and travel. Same for the slide, the pump,
the hinge. It prints the numbers to the log; they go into the archetype's data lump. The rig is the only
tool because the rig is where the measuring happens, by hand, where it will be used. Frames of each step
are the proof.

## What the engine gives and does not
HUD models per layer placed per rendered frame (`ModifyBobLayer3D`) — yes. World actors — yes. Haptics and
sounds on events — yes. Per-player playsim state so netplay holds — yes, by our rule. No collision between
parts and no physics: gravity on a dropped part is ours to write; grabbing is proximity, not a raycast
against the mesh. Nothing above needs more.

## First deliverable
One pistol, completely true — mag out, drops, pick it up, mag in, slide locks back on empty, rack chambers
a round, fire with the mag out works once, a live round ejects on a rack — judged by the owner in the
headset before a second archetype exists. If the pistol is true, the rifle is the pistol with a longer well
and a charging handle; the revolver and shotguns are the hinge and the free shell, which the pistol already
needs for its ejected round. The Colt M5 (rifle) is already in `assets/src/` and follows.
