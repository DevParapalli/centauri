# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Checks scripts/sync-tokens.py without the network. Run from the repository root."""

import importlib.util
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # importing the script must not litter scripts/__pycache__
SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "sync-tokens.py"
spec = importlib.util.spec_from_file_location("sync_tokens", SCRIPT)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

LS_REMOTE = "\n".join(
    f"{'0' * 40}\trefs/tags/{t}"
    for t in ("v0.2.4", "v0.3.0", "v0.3.9", "v0.3.10", "v0.3.11-rc1", "v0.30.5", "v1.3.2")
)
fail = 0


def check(name: str, got: object, want: object) -> None:
    global fail
    if got == want:
        print(f"ok    sync-tokens {name}")
    else:
        print(f"FAIL  sync-tokens {name}: got {got!r}, want {want!r}")
        fail = 1


check("picks the highest patch numerically", sync.latest_tag(LS_REMOTE, "0.3"), "v0.3.10")
check("ignores other minors and majors", sync.latest_tag(LS_REMOTE, "0.2"), "v0.2.4")
check("returns None without a match", sync.latest_tag(LS_REMOTE, "0.4"), None)
check("does not read 0.30 as 0.3", sync.latest_tag(LS_REMOTE, "0.30"), "v0.30.5")

own = sync.tomllib.loads(sync.PACKAGE.read_text(encoding="utf-8"))["package"]["version"]
major, minor = own.split(".")[:2]
for ref, why in (
    (f"{major}.{minor}.0", "a full version"),
    ("latest", "a non-version"),
    (f"{major}.{int(minor) + 1}", "a minor other than typst.toml's"),
    (f"v{int(major) + 1}.{minor}", "a major other than typst.toml's"),
):
    run = subprocess.run(
        [sys.executable, str(SCRIPT), "--ref", ref, "--check"], capture_output=True, text=True, timeout=30
    )
    check(f"rejects {why} ({ref})", (run.returncode, run.stderr.startswith("error: --ref")), (2, True))

sys.exit(fail)
