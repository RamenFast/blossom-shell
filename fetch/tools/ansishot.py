#!/usr/bin/env python3
"""ansishot — render ANSI terminal output to a PNG the way a real terminal does.

A tiny terminal emulator: it lays a byte stream onto a character grid honouring
newlines, SGR colours, and the cursor-column moves (CHA `ESC[..G`, CUF `ESC[..C`)
that fastfetch uses to align values — then paints the grid with a real monospace
font at the real cell aspect (font line-height x kitty's line-height multiplier)
and the 1905 terminal palette. Lets me SEE what Ben sees and design against it.

  fastfetch --pipe false --config X | ansishot.py -o shot.png
"""
import sys, argparse
from PIL import Image, ImageDraw, ImageFont

# --- 1905 terminal palette (Ben's kitty theme) -------------------------------
BG = (0x1c, 0x14, 0x10); FG = (0xe8, 0xdc, 0xcb)
P16 = [(0x1c,0x14,0x10),(0xc2,0x75,0x6a),(0x8a,0x9a,0x6a),(0xd4,0x9a,0x4a),
       (0x6a,0x8a,0x9a),(0x9a,0x7a,0x9a),(0x7a,0x9a,0xa0),(0xb8,0xa8,0x98),
       (0x4a,0x3a,0x30),(0xe8,0x9a,0x8a),(0xa8,0xb8,0x88),(0xf0,0xc0,0x84),
       (0x8a,0xac,0xbc),(0xbc,0x9c,0xbc),(0x9a,0xbc,0xc0),(0xe8,0xdc,0xcb)]

def xterm(n):
    if n < 16: return P16[n]
    if n < 232:
        n -= 16; r, g, b = n // 36, (n // 6) % 6, n % 6
        f = lambda v: 0 if v == 0 else 55 + v * 40
        return (f(r), f(g), f(b))
    v = 8 + (n - 232) * 10; return (v, v, v)

class Cell:
    __slots__ = ("ch", "fg", "bg")
    def __init__(s, ch, fg, bg): s.ch, s.fg, s.bg = ch, fg, bg

def emulate(data):
    grid = {}; row = col = 0; maxr = maxc = 0
    fg, bg, bold = FG, None, False
    i, n = 0, len(data)
    while i < n:
        c = data[i]
        if c == "\x1b" and i + 1 < n and data[i+1] == "[":
            j = i + 2
            while j < n and not data[j].isalpha(): j += 1
            params = data[i+2:j]; final = data[j] if j < n else "m"
            nums = [int(x) for x in params.split(";") if x.isdigit()] if params else []
            if final == "m":
                k = 0
                if not nums: nums = [0]
                while k < len(nums):
                    p = nums[k]
                    if p == 0: fg, bg, bold = FG, None, False
                    elif p == 1: bold = True
                    elif p == 22: bold = False
                    elif 30 <= p <= 37: fg = P16[(p-30) + (8 if bold else 0)]
                    elif p == 39: fg = FG
                    elif 90 <= p <= 97: fg = P16[8 + p-90]
                    elif 40 <= p <= 47: bg = P16[p-40]
                    elif p == 49: bg = None
                    elif 100 <= p <= 107: bg = P16[8 + p-100]
                    elif p in (38, 48):
                        tgt = "fg" if p == 38 else "bg"
                        if k+1 < len(nums) and nums[k+1] == 5:
                            col_rgb = xterm(nums[k+2]); k += 2
                        elif k+1 < len(nums) and nums[k+1] == 2:
                            col_rgb = (nums[k+2], nums[k+3], nums[k+4]); k += 4
                        else: col_rgb = FG
                        if tgt == "fg": fg = col_rgb
                        else: bg = col_rgb
                    k += 1
            elif final == "G": col = (nums[0]-1) if nums else 0
            elif final == "C": col += (nums[0] if nums else 1)
            elif final == "D": col = max(0, col - (nums[0] if nums else 1))
            i = j + 1; continue
        if c == "\n": row += 1; col = 0
        elif c == "\r": col = 0
        elif c == "\t": col += 8 - (col % 8)
        elif c == "\x1b": pass
        else:
            grid[(row, col)] = Cell(c, fg, bg); col += 1
            maxr = max(maxr, row); maxc = max(maxc, col)
        i += 1
    return grid, maxr, maxc

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--out", default="/tmp/ansishot.png")
    ap.add_argument("--font", default="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")
    ap.add_argument("--size", type=int, default=26)
    ap.add_argument("--lineheight", type=float, default=1.30)   # kitty adjust_line_height
    args = ap.parse_args()

    data = sys.stdin.read()
    grid, maxr, maxc = emulate(data)
    font = ImageFont.truetype(args.font, args.size)
    asc, desc = font.getmetrics()
    cw = round(font.getlength("█"))
    natural = asc + desc
    ch = round(natural * args.lineheight)
    yoff = (ch - natural) // 2

    W = (maxc + 2) * cw; H = (maxr + 2) * ch
    img = Image.new("RGB", (W, H), BG); d = ImageDraw.Draw(img)
    for (r, cidx), cell in grid.items():
        x = (cidx + 1) * cw; y = (r + 1) * ch
        if cell.bg is not None:
            d.rectangle([x, y, x + cw, y + ch], fill=cell.bg)
        d.text((x, y + yoff), cell.ch, font=font, fill=cell.fg)
    img.save(args.out)
    print(f"{args.out}  ({W}x{H}, cell {cw}x{ch}, aspect {ch/cw:.2f})")

if __name__ == "__main__":
    main()
