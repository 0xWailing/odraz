#!/usr/bin/env python3
"""Checks the generated launcher icon sources. Run from the repo root:
    python3 -I tools/check_launcher_icons.py
Exit code 1 on failure."""
import math
import sys
from pathlib import Path

from PIL import Image

FG = Path("assets/icon/odraz_icon_foreground.png")
LEGACY = Path("assets/icon/odraz_icon_legacy.png")
SNOW = (0xFA, 0xF8, 0xF2)
NIGHT = (0x18, 0x04, 0x48)
errors = []


def check(cond, msg):
    if not cond:
        errors.append(msg)


def bbox_of(mask_img):
    box = mask_img.getbbox()
    return box if box else (0, 0, 0, 0)


for p in (FG, LEGACY):
    check(p.exists(), f"missing {p}")
if errors:
    print("\n".join(errors))
    sys.exit(1)

fg = Image.open(FG).convert("RGBA")
check(fg.size == (1024, 1024), f"{FG} must be 1024x1024, got {fg.size}")
alpha = fg.getchannel("A")
for corner in [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]:
    check(alpha.getpixel(corner) == 0, f"{FG} corner {corner} must be transparent")
x0, y0, x1, y1 = bbox_of(alpha.point(lambda a: 255 if a > 128 else 0))
height = (y1 - y0) / 1024
check(0.59 <= height <= 0.62, f"foreground hexagon height ratio {height:.3f} not in 0.59-0.62")
check(abs((x0 + x1) / 2 - 512) <= 8, "foreground hexagon not horizontally centered")
check(abs((y0 + y1) / 2 - 512) <= 8, "foreground hexagon not vertically centered")

px = fg.load()
opaque = dark = 0
far = 0.0
for y in range(1024):
    for x in range(1024):
        r, g, b, a = px[x, y]
        if a > 128:
            far = max(far, math.hypot(x - 511.5, y - 511.5))
        if a > 250:
            opaque += 1
            if all(abs(c - n) <= 45 for c, n in zip((r, g, b), NIGHT)):
                dark += 1
check(opaque > 0 and dark / opaque >= 0.35, "foreground is not mostly the dark violet hexagon")
check(far <= 335, f"foreground pixel {far:.0f}px from center, must stay within 335px of the 1024px layer")

leg = Image.open(LEGACY).convert("RGB")
check(leg.size == (1024, 1024), f"{LEGACY} must be 1024x1024, got {leg.size}")
check(all(abs(a - b) <= 2 for a, b in zip(leg.getpixel((0, 0)), SNOW)), "legacy corner must be #FAF8F2")
diff = leg.point(lambda v: v).convert("RGB")
mask = Image.new("L", leg.size, 0)
lp, mp = leg.load(), mask.load()
for y in range(1024):
    for x in range(1024):
        if sum(abs(c - s) for c, s in zip(lp[x, y], SNOW)) > 120:
            mp[x, y] = 255
lx0, ly0, lx1, ly1 = bbox_of(mask)
lh, lw = (ly1 - ly0) / 1024, (lx1 - lx0) / 1024
check(0.88 <= lh <= 0.95, f"legacy hexagon height ratio {lh:.3f} not in 0.88-0.95")
check(lw >= 0.78, f"legacy hexagon width ratio {lw:.3f} below 0.78")

if errors:
    print("FAIL:\n  " + "\n  ".join(errors))
    sys.exit(1)
print("launcher icon sources OK")
