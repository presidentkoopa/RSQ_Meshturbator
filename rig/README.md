# rig/ — QuestZDoom 17.3 for Linux, driven from cvars (TEST ONLY, never ships)

Emawind's QuestZDoom 17.3 (tag `qzd17.3`, gzdoom 9afc750 — the release the owner and his players run), built
for Linux on the OpenXR code path with the OpenXR/JNI layer replaced by `engine/glue/qz_linux_glue.cpp`, so the
headset and both controllers are posed from cvars and the left eye renders to image files. `PINS` names the one
engine allowed; `bin/qz` refuses any other and prints `qz: engine OK: ...` on every launch.

- `sh rig/setup.sh` — check the prebuilt `bin/` answers and is 17.3. `sh rig/setup.sh build` rebuilds it from PINS.
- `python3 rig/rig.py check` — one engine run; `python3 rig/rig.py run <name> <pk3...> "<console script>"`.
- `rig.py` is the whole driver: `run()`, `lpose()`, frame dumps, flock, ini restore. Test scripts for a feature
  live beside it and import it; they drive, they never measure a mesh.

Carried over from RS_ModelSwapper `tools/rig` (2026-11-09) with the MS-specific drivers and probes left behind.
The prebuilt `bin/qzdoom` is byte-identical to a `setup.sh build` from PINS (RSQ_WeaponDepot, 2026-10-26).
`bin/config/qzdoom.ini` is the test ini; `bin/saves/` and `bin/libGLESv3.so` are made at run time (gitignored).
