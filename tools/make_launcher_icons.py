#!/usr/bin/env python3
"""Builds the launcher icon sources from assets/icon/odraz_logo.png.
Run from the repo root:  python3 -I tools/make_launcher_icons.py

Outputs (1024x1024):
  assets/icon/odraz_icon_foreground.png  adaptive-icon foreground: transparent
                                         outside the hexagon, hexagon height 60.5%
  assets/icon/odraz_icon_legacy.png      pre-Android-8 icon: hexagon height 92%
                                         on the #F9FAFB brand background
"""
import math
from collections import deque
from pathlib import Path

from PIL import Image

SRC = Path("assets/icon/odraz_logo.png")
BG = (0xF9, 0xFA, 0xFB)
HEX = (26, 4, 80)  # hexagon edge color (deep violet)
HEX_BG_DIST = math.dist(HEX, BG)
SIZE = 1024


def knock_out_background(img: Image.Image) -> Image.Image:
    """Make the outside background transparent: flood-fill from the corners,
    then un-mix the anti-aliased edge pixels into partial alpha."""
    w, h = img.size
    px = img.load()
    dist = [[math.dist(px[x, y], BG) for x in range(w)] for y in range(h)]
    ext = [[False] * w for _ in range(h)]
    dq = deque()
    for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ext[c[1]][c[0]] = True
        dq.append(c)
    while dq:
        x, y = dq.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not ext[ny][nx] and dist[ny][nx] < 30:
                ext[ny][nx] = True
                dq.append((nx, ny))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    # edge band: up to 3 pixels inside the exterior region
    layer = deque()
    band = {}
    for y in range(h):
        for x in range(w):
            if ext[y][x]:
                continue
            if any(0 <= x + dx < w and 0 <= y + dy < h and ext[y + dy][x + dx]
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                band[(x, y)] = 1
                layer.append((x, y))
    while layer:
        x, y = layer.popleft()
        d = band[(x, y)]
        if d >= 3:
            continue
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not ext[ny][nx] and (nx, ny) not in band:
                band[(nx, ny)] = d + 1
                layer.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if ext[y][x]:
                continue
            if (x, y) in band:
                a = max(0.0, min(1.0, dist[y][x] / HEX_BG_DIST))
                op[x, y] = (*HEX, round(255 * a))
            else:
                op[x, y] = (*px[x, y], 255)
    return out


def main() -> None:
    hexa = knock_out_background(Image.open(SRC).convert("RGB"))
    hexa = hexa.crop(hexa.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())
    hw, hh = hexa.size

    def placed(target_height: int, bg) -> Image.Image:
        scale = target_height / hh
        img = hexa.resize((round(hw * scale), target_height), Image.LANCZOS)
        canvas = Image.new("RGBA", (SIZE, SIZE), bg)
        canvas.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
        return canvas

    placed(round(0.605 * SIZE), (0, 0, 0, 0)).save("assets/icon/odraz_icon_foreground.png")
    placed(round(0.92 * SIZE), (*BG, 255)).convert("RGB").save("assets/icon/odraz_icon_legacy.png")
    print("wrote assets/icon/odraz_icon_foreground.png and odraz_icon_legacy.png")


if __name__ == "__main__":
    main()
