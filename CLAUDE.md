# RSQ_Meshturbator — standing rules (owner: presidentkoopa)

**Mission (owner, 2026-11-09):** Universal hand-reloading weapon meshes (and non-reloading melee things) to
attach to any weapon code from any Doom mod ever made. A TRUE reload system, built from the ground up: real
parts moved by real hands under real constraints — not surface hiding (what BD22 had to do with fused MD3s).
No tools go into the repo: just the rig and what is needed to run it in VR and drive the controllers.

Read `DESIGN.md` (the system) and `HANDOFF.md` (what is done, measured; what is not; what is open) before any work.
**Before beginning any work, tell the owner what you are about to do and wait for his yes.**

## The rules
1. **One tool per number: the rig.** A measurement is a frame or a log from the rig (`rig/`), nothing else
   measures a mesh. Joints are measured by hand, in VR, in the engine's fitting mode, once per library mesh.
   No measuring scripts, no generators, no "kits". If something must be computed it is computed in ZScript
   in the pack, or in `rig/rig.py` to drive a test — and its result is shown in frames.
2. **No engine changes.** QuestZDoom 17.3 (the commits in `rig/PINS`), stock. ZScript, MODELDEF and data only.
3. **Our meshes, not the mod's.** One mesh per archetype, parts as separate named objects from the source
   file. A mod's weapon is only ever asked one thing: which archetype are you.
4. **The ammo gate is the only seam to a mod.** `Ammo1` is our magazine's count each tic; the mod's fire code
   fires or doesn't and never knows why. A mod with its own magazine system gets ONE exception line.
5. **Zero script errors before the headset.** Nothing goes to the owner until it loaded on the rig with no
   script error from the pack. Asked "do you have a pk3?" before that, the answer is "not yet".
6. **Shown working only.** Working means in-engine frames or a log of the behaviour, never "the code exists"
   or "it compiles". Rig behaviour is "rig only, not headset-confirmed" until the owner says so.
7. **One method.** The gun moves to the hand; everything on the gun moves with it.
8. **Look at every frame.** Numbers lie.
9. **Netplay holds.** Play state is per player in the playsim; no `consoleplayer` in play logic; loop players;
   rendering is per frame and reads state, never writes it.
10. **Say a blocker the moment it appears.** Never work round it silently. Don't narrate tests every turn;
    ask in one line before any rig run the owner did not name. Never tell the owner when to sleep or work.
11. **Keep `HANDOFF.md` current:** done (measured), not done, open — in that order, same commit as the code.
12. **Read before describing.** Never describe a repo, a mod or a file from memory or a README; open it.
    Verify an agent's report against the files before repeating it.

## Layout
- `rig/` — the QuestZDoom 17.3 Linux rig: `bin/` (prebuilt engine, launcher `qz` with the version guard),
  `engine/` (source of the OpenXR glue and the build), `PINS`, `setup.sh`, `rig.py` (poses, frame dumps, runs).
- `assets/src/` — the mesh sources as downloaded (see `assets/ASSETS.md` for author and licence). Exported
  MD3s go beside them when they exist.
- `pack/` — the pk3 contents (ZScript, MODELDEF, data). Does not exist yet.
- Game data is the owner's and never committed: `$MT_GAMEDATA` (default `/home/claude/rig/packs`).
