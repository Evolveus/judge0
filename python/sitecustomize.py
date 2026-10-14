"""Start-up setup for Python (3.8.1) submissions, language id 71.

Installed into that interpreter's site-packages by the Dockerfile, so it runs at
the start of every Python submission, inside the isolate sandbox. It must be
cheap, and it must never raise: an exception here fails the student's program
before a line of it has run.
"""

import os

# One BLAS/OpenMP thread. numpy otherwise starts a thread per core, and isolate's
# process/thread limit (-p) kills the submission before it runs.
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("OMP_NUM_THREADS", "1")

# There is no display in the sandbox. Agg also makes plt.show() a no-op that
# keeps figures open.
os.environ.setdefault("MPLBACKEND", "Agg")

# Matplotlib's font cache, built once into the image (see the Dockerfile).
# Without it, every submission that imports matplotlib scans the system fonts
# and rebuilds the cache, because each sandbox starts empty. The prebuilt copy
# cannot be used in place: /usr is read-only in the sandbox, and matplotlib
# ignores a config dir it cannot write to, then rebuilds in a temp dir anyway.
# So it is copied into the sandbox's writable /tmp (HOME), a few hundred KB.
_PREBUILT_MPL_CACHE = "/usr/local/share/matplotlib-cache"
_SANDBOX_MPL_CONFIGDIR = "/tmp/matplotlib"


def _seed_matplotlib_cache():
    if "MPLCONFIGDIR" in os.environ:
        return
    try:
        names = [n for n in os.listdir(_PREBUILT_MPL_CACHE) if n.startswith("fontlist-")]
        if not names:
            return
        os.makedirs(_SANDBOX_MPL_CONFIGDIR, exist_ok=True)
        for name in names:
            target = os.path.join(_SANDBOX_MPL_CONFIGDIR, name)
            if os.path.exists(target):
                continue
            with open(os.path.join(_PREBUILT_MPL_CACHE, name), "rb") as src:
                data = src.read()
            with open(target, "wb") as dst:
                dst.write(data)
    except OSError:
        # Matplotlib falls back to building its own cache: slower, still correct.
        return
    os.environ["MPLCONFIGDIR"] = _SANDBOX_MPL_CONFIGDIR


_seed_matplotlib_cache()
