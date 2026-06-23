#!/usr/bin/env python3
"""Recolour an Xcursor theme into a Blossom palette — losslessly.

Bibata (and most cursor themes) are two-tone: a dark FILL and a light OUTLINE,
with alpha carrying the shape + antialiasing. We remap tone -> colour by the
pixel's luminance (0 = fill, 1 = outline) and keep alpha untouched, so every
shape, size and animation frame survives exactly — only the colour changes.

Xcursor files are edited in place (same dimensions => the table of contents and
chunk offsets stay valid); we only rewrite the ARGB pixel bytes of each image
chunk. Symlinks (default -> left_ptr, etc.) are recreated in the output.

Usage:
  blossom-cursorize.py --src DIR --dest DIR --name "Blossom Rose" \
      --fill db3776 --outline f7e7c0
"""
import os, struct, argparse, shutil

IMG_TYPE = 0xfffd0002

def hex2rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

def recolour_bytes(data, fill, outline):
    b = bytearray(data)
    magic, hsize, ver, ntoc = struct.unpack_from("<4sIII", b, 0)
    if magic != b"Xcur":
        raise ValueError("not an Xcursor file")
    fr, fg, fb = fill
    orr, og, ob = outline
    cache = {}                      # (B,G,R,A) packed -> (nB,nG,nR); solid runs repeat
    def remap(B, G, R, A):
        # un-premultiply for a true tone, then remap fill->outline by luminance
        uR = min(255, R * 255 // A); uG = min(255, G * 255 // A); uB = min(255, B * 255 // A)
        L = (0.2126 * uR + 0.7152 * uG + 0.0722 * uB) / 255.0
        nR = fr + (orr - fr) * L; nG = fg + (og - fg) * L; nB = fb + (ob - fb) * L
        return (int(nB * A / 255), int(nG * A / 255), int(nR * A / 255))   # re-premultiplied
    off = hsize
    for _ in range(ntoc):
        typ, sub, pos = struct.unpack_from("<III", b, off); off += 12
        if typ != IMG_TYPE:
            continue
        chsize, ctyp, csub, cver, w, h, xh, yh, delay = struct.unpack_from("<IIIIIIIII", b, pos)
        px = pos + chsize
        for i in range(w * h):
            o = px + i * 4
            A = b[o+3]
            if A == 0:
                continue
            key = b[o] | b[o+1] << 8 | b[o+2] << 16 | A << 24
            v = cache.get(key)
            if v is None:
                v = remap(b[o], b[o+1], b[o+2], A); cache[key] = v
            b[o], b[o+1], b[o+2] = v
    return bytes(b)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--dest", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--fill", required=True)
    ap.add_argument("--outline", required=True)
    ap.add_argument("--comment", default="Blossom-themed cursors.")
    a = ap.parse_args()

    fill, outline = hex2rgb(a.fill), hex2rgb(a.outline)
    src_cur = os.path.join(a.src, "cursors")
    dst_cur = os.path.join(a.dest, "cursors")
    os.makedirs(dst_cur, exist_ok=True)

    files = symlinks = 0
    for name in sorted(os.listdir(src_cur)):
        sp = os.path.join(src_cur, name)
        dp = os.path.join(dst_cur, name)
        if os.path.islink(sp):
            tgt = os.readlink(sp)
            if os.path.lexists(dp): os.remove(dp)
            os.symlink(tgt, dp); symlinks += 1
        elif os.path.isfile(sp):
            with open(sp, "rb") as fh:
                out = recolour_bytes(fh.read(), fill, outline)
            with open(dp, "wb") as fh:
                fh.write(out)
            files += 1

    with open(os.path.join(a.dest, "index.theme"), "w") as fh:
        fh.write(f"[Icon Theme]\nName={a.name}\nComment={a.comment}\nInherits=hicolor\n")
    with open(os.path.join(a.dest, "cursor.theme"), "w") as fh:
        fh.write(f"[Icon Theme]\nName={a.name}\nInherits={os.path.basename(a.dest)}\n")
    print(f"  ❀ {a.name}: {files} cursors recoloured, {symlinks} aliases → {a.dest}")

if __name__ == "__main__":
    main()
