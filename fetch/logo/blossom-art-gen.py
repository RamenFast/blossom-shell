#!/usr/bin/env python3
"""Generate the Blossom logo for fastfetch — a half-block 5-petal sakura.

Terminal cells are ~2.6x taller than wide (DejaVu Sans Mono + kitty's 130% line
height), so full-block art can't curve — it reads as stacked bars. The fix is
half-block rendering: we rasterise the bloom at 2x vertical resolution and pack
each pair of stacked pixels into one cell via ▀ / ▄ / █, so a *pixel* is only
~1.3x tall and curves read smoothly.

Each petal is an ellipse pushed out along its axis (gap between neighbours), with
a heart-cleft notched tip; five at 72deg, plus a core. Output carries fastfetch
colour placeholders ($1 petals, $2 core, $3 soft edge), stripped for width and
swapped for logo.color.{1,2,3} — so it stays adaptive to the terminal palette.
"""
import math, argparse

CELL_ASPECT = 2.02          # cell height / width with standard line height (DejaVu mono)
PIX = CELL_ASPECT / 2.0     # a half-block pixel is this many times taller than wide

COL = {1: "$1", 2: "$2", 3: "$3"}

def render(W, H2, rc, pa, pb, core, notch, edge=0.0):
    """Rasterise the bloom onto a W x H2 pixel grid (H2 = 2 * character rows)."""
    cx, cy = (W - 1) / 2.0, (H2 - 1) / 2.0
    R = min(cx, cy * PIX)
    petals = [math.radians(-90 + i * 72) for i in range(5)]
    g = [[0] * W for _ in range(H2)]
    for row in range(H2):
        for col in range(W):
            x = (col - cx) / R
            y = (row - cy) * PIX / R
            if math.hypot(x, y) <= core:
                g[row][col] = 2; continue
            best = -1.0
            for a in petals:
                u = x * math.cos(a) + y * math.sin(a)
                v = -x * math.sin(a) + y * math.cos(a)
                tip = rc + pa
                if u > tip - notch and abs(v) < (u - (tip - notch)) * 0.95:
                    continue                         # heart cleft at the petal tip
                d = ((u - rc) / pa) ** 2 + (v / pb) ** 2
                best = max(best, 1.0 - d)
            if best > 0:
                g[row][col] = 3 if (edge and best < edge) else 1
    return g

def denoise(g):
    h, w = len(g), len(g[0])
    keep = [r[:] for r in g]
    for y in range(h):
        for x in range(w):
            if not g[y][x]:
                continue
            n = sum(1 for dy in (-1,0,1) for dx in (-1,0,1)
                    if (dy or dx) and 0 <= y+dy < h and 0 <= x+dx < w and g[y+dy][x+dx])
            if n < 2:
                keep[y][x] = 0
    return keep

def pack(g):
    """Pack pixel rows two-at-a-time into half-block characters."""
    if len(g) % 2:
        g = g + [[0] * len(g[0])]
    out = []
    for r in range(0, len(g), 2):
        top, bot = g[r], g[r + 1]
        line, cur = [], None
        for c in range(len(top)):
            zt, zb = top[c], bot[c]
            if not zt and not zb:
                line.append(" "); cur = None; continue
            if zt and not zb:   ch, z = "▀", zt
            elif zb and not zt: ch, z = "▄", zb
            elif zt == zb:      ch, z = "█", zt
            else:               ch, z = "█", (2 if 2 in (zt, zb) else 1)
            if z != cur:
                line.append(COL[z]); cur = z
            line.append(ch)
        out.append("".join(line).rstrip())
    while out and not out[0].strip():  out.pop(0)
    while out and not out[-1].strip(): out.pop()
    return "\n".join(out) + "\n"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mini", action="store_true")
    a = ap.parse_args()
    if a.mini:
        g = render(W=30, H2=28, rc=0.50, pa=0.48, pb=0.40, core=0.25, notch=0.10)
    else:
        g = render(W=40, H2=38, rc=0.50, pa=0.48, pb=0.40, core=0.28, notch=0.10)
    print(pack(denoise(g)), end="")

if __name__ == "__main__":
    main()
