#!/usr/bin/env python3
"""Checks that the Android icon set is wired up consistently. Run from the repo root:
    python3 -I tools/check_android_icons.py
Exit code 1 on failure."""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

RES = Path("android/app/src/main/res")
MANIFEST = Path("android/app/src/main/AndroidManifest.xml")
DENSITIES = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]
errors = []


def check(cond, msg):
    if not cond:
        errors.append(msg)


manifest = MANIFEST.read_text()
check('android:icon="@mipmap/ic_launcher"' in manifest, "manifest must use @mipmap/ic_launcher")
check('android:roundIcon="@mipmap/ic_launcher_round"' in manifest,
      "manifest must use @mipmap/ic_launcher_round")

for d in DENSITIES:
    for name in ["ic_launcher", "ic_launcher_round", "ic_launcher_foreground", "ic_launcher_monochrome"]:
        check((RES / f"mipmap-{d}" / f"{name}.png").exists(), f"missing mipmap-{d}/{name}.png")

for name in ["ic_launcher", "ic_launcher_round"]:
    xml = RES / "mipmap-anydpi-v26" / f"{name}.xml"
    check(xml.exists(), f"missing {xml}")
    if xml.exists():
        text = xml.read_text()
        for tag in ("background", "foreground", "monochrome"):
            check(f"<{tag} " in text, f"{xml} has no <{tag}>")

# every color name must be defined exactly once across values/*.xml
colors = {}
for f in (RES / "values").glob("*.xml"):
    for c in ET.parse(f).getroot().iter("color"):
        colors.setdefault(c.get("name"), []).append(f.name)
for name, files in colors.items():
    check(len(files) == 1, f"color {name} defined more than once: {files}")
check("ic_launcher_background" in colors, "ic_launcher_background color is not defined")

# nothing may refer to the old generated names
old = [p for p in RES.rglob("*") if p.is_file() and "launcher_icon" in p.name]
check(not old, f"old generated icon files remain: {[str(p) for p in old]}")
stale = [p for p in RES.rglob("drawable-*/ic_launcher_foreground.png")]
check(not stale, f"old drawable foregrounds remain: {[str(p) for p in stale]}")
for p in list(Path("android").rglob("*.xml")) + list(Path("android").rglob("*.kts")):
    if "build" in p.parts:
        continue
    check("launcher_icon" not in p.read_text(errors="ignore") or p.name == "check",
          f"{p} still mentions launcher_icon")

play = Path("assets/branding/playstore_icon_512.png")
check(play.exists(), "missing assets/branding/playstore_icon_512.png")
if play.exists():
    im = Image.open(play)
    check(im.size == (512, 512) and im.mode == "RGB", f"play store icon must be 512x512 RGB, got {im.size} {im.mode}")

logo = Path("assets/icon/odraz_logo.png")
im = Image.open(logo).convert("RGBA")
check(im.getpixel((0, 0))[3] == 0 and im.getpixel((im.width - 1, im.height - 1))[3] == 0,
      "in-app logo must have a transparent background")

if errors:
    print("FAIL:\n  " + "\n  ".join(errors))
    sys.exit(1)
print("android icon set OK")
