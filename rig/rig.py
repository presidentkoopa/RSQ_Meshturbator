"""The rig driver. TEST ONLY, never ships. The one script that drives the engine.

    python3 rig/rig.py check                      the engine answers and is QuestZDoom 17.3
    python3 rig/rig.py run <name> <file.pk3 ...> "<console script>"   one run, log in rig/runs/<name>.log

As a module (from a test script in rig/):
    import rig
    text = rig.run('t1', [pk3, ...], 'wait 60; give Pistol; wait 35; quit', dump=8)   # frames every 8 tics
    rig.lpose(F, L, U)      # a point in the gun's frame (cm, forward/left/up) -> a qz_lhand pose string

The engine: rig/bin (prebuilt QuestZDoom 17.3; bin/qz refuses anything else), or $MT_RIG.
Game data: $MT_GAMEDATA (default /home/claude/rig/packs) must hold doom2.wad.
One engine at a time on a shared machine: every run takes flock on /home/claude/rig.lock.
The engine reads and writes bin/config/qzdoom.ini relative to its cwd and ignores -config, so the
committed ini is restored from git before and after every run.

Controllers are cvars the glue reads every tic (rig/engine/glue/qz_linux_glue.cpp):
    qz_hmd / qz_rhand / qz_lhand  "x y z pitch yaw roll"   stage metres, degrees
    qz_rtrigger qz_rgrip qz_ltrigger qz_lgrip  0..1        qz_rstick / qz_lstick "x y"
A pack-defined qzt_<same> cvar overrides the qz_ one, so ZScript can drive a controller from inside.
Known limit (ModelSwapper rig, 2026-11-09): a posed controller ROLL does not reach ZScript (read as 0).
Frame dumps: QZ_RES=<px> QZ_DUMP_EVERY=<n> QZ_DUMP_DIR=<dir> (left eye, .ppm, named by tic).
"""
import os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
RIG = os.environ.get('MT_RIG', HERE + '/bin')
DATA = os.environ.get('MT_GAMEDATA', '/home/claude/rig/packs')
IWAD = os.path.join(DATA, 'doom2.wad')
OUT = HERE + '/runs'
INI = os.path.join(RIG, 'config', 'qzdoom.ini')
LOCK = '/home/claude/rig.lock'

# the gun hand's default pose (qz_rhand default in the glue); the off hand is placed relative to it
RHAND = (0.25, 1.3, -0.3)


def lpose(F, L, U, pitch=30.0, yaw=0.0, roll=0.0):
    """a point in the gun's frame (cm: forward, left, up) -> qz_lhand, oriented like the gun hand"""
    return '%.4f %.4f %.4f %.1f %.1f %.1f' % (RHAND[0] - L / 100.0, RHAND[1] + U / 100.0,
                                             RHAND[2] - F / 100.0, pitch, yaw, roll)


def reset_ini():
    repo = os.path.dirname(HERE)
    subprocess.call(['git', '-C', repo, 'checkout', '--', os.path.relpath(INI, repo)],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run(name, files, script, secs=240, dump=0, res=480, extra_env=None):
    """one engine run on doom2 + files, with one chained console script; returns log + stdout text.
    dump=n writes a frame every n tics to rig/runs/<name>_frames/"""
    if not os.path.exists(IWAD):
        sys.exit('rig: no doom2.wad at %s (set MT_GAMEDATA)' % DATA)
    os.makedirs(OUT, exist_ok=True)
    reset_ini()
    log = '%s/%s.log' % (OUT, name)
    for f in (log, log + '.out'):
        if os.path.exists(f):
            os.remove(f)
    env = dict(os.environ, QZ_RES=str(res), EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1')
    if dump:
        d = '%s/%s_frames' % (OUT, name)
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(d):
            os.remove(os.path.join(d, f))
        env.update(QZ_DUMP_EVERY=str(dump), QZ_DUMP_DIR=d)
    if extra_env:
        env.update(extra_env)
    cmd = ['flock', '-o', '-x', LOCK, 'timeout', str(secs), RIG + '/qz', '-iwad', IWAD]
    if files:
        cmd += ['-file'] + [os.path.abspath(f) for f in files]
    cmd += ['-nosound', '-nomusic', '-warp', '1', '-skill', '3', '+logfile', log, '+' + script]
    with open(log + '.out', 'w') as fo:
        subprocess.run(cmd, stdout=fo, stderr=subprocess.STDOUT, cwd=RIG, env=env)
    reset_ini()
    t = ''
    for f in (log, log + '.out'):
        if os.path.exists(f):
            t += open(f, errors='replace').read()
    return t


def errors(text):
    import re
    return [l for l in text.splitlines() if re.search(r'Script error|VM abort|VM execution aborted|Execution could not continue|exception', l)]


if __name__ == '__main__':
    a = sys.argv[1:]
    if not a or a[0] == 'check':
        t = run('check', [], 'wait 35; quit', 120)
        ok = [l for l in t.splitlines() if 'qz: engine OK' in l]
        print(ok[0] if ok else 'rig: engine did not report OK\n' + t[-2000:])
        sys.exit(0 if ok else 1)
    if a[0] == 'run' and len(a) >= 3:
        t = run(a[1], a[2:-1], a[-1])
        print('\n'.join(errors(t)) or 'no script errors')
        print('log: %s/%s.log' % (OUT, a[1]))
        sys.exit(0)
    print(__doc__)
