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


def ls_remote(*tags: str) -> str:
    return "\n".join(f"{'0' * 40}\trefs/tags/{t}" for t in tags)


fail = 0


def check(name: str, got: object, want: object) -> None:
    global fail
    if got == want:
        print(f"ok    sync-tokens {name}")
    else:
        print(f"FAIL  sync-tokens {name}: got {got!r}, want {want!r}")
        fail = 1


check("picks the highest patch numerically", sync.latest_tag(ls_remote("v0.3.9", "v0.3.10", "v0.2.4")), "v0.3.10")
check("picks the highest minor numerically", sync.latest_tag(ls_remote("v0.9.9", "v0.10.0")), "v0.10.0")
check("picks the highest major", sync.latest_tag(ls_remote("v0.30.5", "v1.0.0", "v0.3.0")), "v1.0.0")
check("ignores pre-release tags", sync.latest_tag(ls_remote("v0.3.0", "v0.4.0-rc1")), "v0.3.0")
check("returns None without a release tag", sync.latest_tag(ls_remote("draft", "v0.4")), None)

for ref, why in (("latest", "a non-version"), ("0.3", "a major.minor"), ("v0.3.0-rc1", "a pre-release")):
    run = subprocess.run(
        [sys.executable, str(SCRIPT), "--ref", ref, "--check"], capture_output=True, text=True, timeout=30
    )
    check(f"rejects {why} ({ref})", (run.returncode, run.stderr.startswith("error: --ref")), (2, True))

sys.exit(fail)
