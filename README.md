# RSQ_Meshturbator

Universal hand-reloading weapon meshes for any Doom mod, on stock QuestZDoom 17.3.

One mesh per weapon archetype, built from real parts: the magazine is an object, the slide is an object, a
shell is a shell. Your hands move them under real constraints — pull the mag, drop it, pick it up, seat a
fresh one, rack the slide. The gun has real mechanical state (chambered, locked back, action open). A mod's
weapon is attached through one seam, its ammo count, so any weapon from any mod reloads this way without
knowing it.

- `DESIGN.md` — the system, five pieces.
- `CLAUDE.md` — the rules. The short version: the rig is the only tool, no engine changes, shown working only.
- `HANDOFF.md` — what is done (measured), not done, open.
- `rig/` — QuestZDoom 17.3 for Linux with the controllers driven from cvars; frames out, logs out.
- `assets/src/` — mesh sources (see `assets/ASSETS.md`).

Status: nothing built yet. First deliverable is one true pistol, judged in the headset.
