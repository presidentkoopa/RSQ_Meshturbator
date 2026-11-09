"""rig driver for the part system (TEST ONLY). python3 rig/mt_test.py <name>
  load    load doom2 + pack, give MT_M5, print script errors and the MT lines
  mag     grab the magazine on the gun, pull it out along its axis, let go (drop), pick it up, seat it
  handle  pull the charging handle fully back and release (a live round ejects, the bolt chambers the next)
  fire    fire the M5 until the bolt locks back
Frames every 4 tics into rig/runs/<name>_frames/. The pack is zipped from pack/ into rig/runs/mt.pk3 first.
"""
import os, sys, re, zipfile
H = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, H)
import rig

PACK = os.path.join(H, 'runs', 'mt.pk3')

def build():
    os.makedirs(os.path.dirname(PACK), exist_ok=True)
    src = os.path.join(os.path.dirname(H), 'pack')
    with zipfile.ZipFile(PACK, 'w', zipfile.ZIP_DEFLATED) as z:
        for dp, dn, fn in os.walk(src):
            dn.sort()
            for f in sorted(fn):
                p = os.path.join(dp, f)
                z.write(p, os.path.relpath(p, src).replace(os.sep, '/'))
    return PACK

# the gun frame of the m5 archetype (pack/MTARCH): the magazine's grab point and axis, the handle's
MAG_GRAB = (14.5, 0, -7); MAG_AXIS = (0, 0, -1); MAG_TRAVEL = 15; MAG_HOLD = (4, 0, -6)   # a carried mag rides the hand at `hold`
MAG_INS = (MAG_GRAB[0] - MAG_HOLD[0], MAG_GRAB[1] - MAG_HOLD[1], MAG_GRAB[2] - MAG_HOLD[2])  # where the HAND must be for the mag's grab point to be at the well
HANDLE_GRAB = (-0.5, 0, 12.2); HANDLE_AXIS = (-1, 0, 0); HANDLE_TRAVEL = 9

def at(p, axis, t):
    return rig.lpose(p[0] + axis[0] * t, p[1] + axis[1] * t, p[2] + axis[2] * t)

def pose(p):
    return 'qz_lhand "%s"' % p

SETUP = 'wait 70; mt_debug 1; god; give MT_M5; qz_hmd "0 1.7 0.25 -40 0 0"; wait 40; netevent mt_state; '

def script(name):
    if name == 'load':
        return SETUP + 'wait 10; quit'
    if name == 'look':
        # the head behind and above the hands looking down at them; the off hand out to the left; a frame
        # every 4 tics (rendering check: are the part layers drawn at all, and where)
        return SETUP + 'qz_lhand "-0.15 1.25 -0.35 30 0 0"; wait 40; netevent mt_state; wait 10; quit'
    if name == 'mag':
        s = SETUP
        s += pose(at(MAG_GRAB, MAG_AXIS, 0)) + '; wait 10; qz_ltrigger 1; wait 6; '      # grab in the well
        for t in (3, 7, 11, 15, 18, 21):                                               # pull it out, past free
            s += pose(at(MAG_GRAB, MAG_AXIS, t)) + '; wait 6; '
        s += 'netevent mt_state; qz_ltrigger 0; wait 40; netevent mt_state; '          # let go: it drops to the floor
        # a fresh one from the pouch: hand low at the hip, grab (edge: the trigger was released above)
        s += 'qz_lhand "-0.1 0.75 -0.2 30 0 0"; wait 10; qz_ltrigger 1; wait 6; netevent mt_state; '
        for t in (18, 12, 8, 4, 1, 0):                                                 # bring it to the well and seat it
            s += pose(at(MAG_INS, MAG_AXIS, t)) + '; wait 6; '
        s += 'netevent mt_state; qz_ltrigger 0; wait 10; netevent mt_state; wait 10; quit'
        return s
    if name == 'handle':
        s = SETUP + pose(at(HANDLE_GRAB, HANDLE_AXIS, 0)) + '; wait 10; qz_ltrigger 1; wait 6; '
        for t in (3, 6, 9, 10):
            s += pose(at(HANDLE_GRAB, HANDLE_AXIS, t)) + '; wait 6; '
        s += 'netevent mt_state; qz_ltrigger 0; wait 20; netevent mt_state; wait 10; quit'
        return s
    if name == 'fire':
        return SETUP + '+attack; wait 120; -attack; wait 20; netevent mt_state; wait 10; quit'
    sys.exit(__doc__)

if __name__ == '__main__':
    name = sys.argv[1] if len(sys.argv) > 1 else 'load'
    pk3 = build()
    t = rig.run('mt_' + name, [pk3], script(name), secs=240, dump=0 if name == 'load' else 4)
    errs = rig.errors(t)
    print('SCRIPT ERRORS: %d' % len(errs))
    for l in errs[:10]: print('  ' + l)
    for l in t.splitlines():
        if l.startswith('MT') or 'engine OK' in l or 'archetype' in l:
            print(l)
