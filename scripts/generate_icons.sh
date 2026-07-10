#!/bin/bash
# =============================================================================
# generate_icons.sh — Resize source icon (or generate fallback) into all the
# sizes that Assets.xcassets/AppIcon.appiconset/Contents.json expects.
# =============================================================================
set -euo pipefail

SRCROOT="${1:-$PWD}"
SRC_ICON="$SRCROOT/icons/icon.png"
OUT_DIR="$SRCROOT/Resources/Assets.xcassets/AppIcon.appiconset"

# ---------- helper: resize one icon with sips ----------
resize() {
    local in="$1" out="$2" size="$3"
    sips -z "$size" "$size" "$in" --out "$out" >/dev/null 2>&1
}

# ---------- fallback: generate a checkra1n-style icon in pure Python ----------
generate_fallback() {
    local out="$1" size="${2:-1024}"
    echo "  → Generating fallback icon (${size}×${size}) with Python…"
    python3 -c "
import struct, zlib, math

SZ = $size
pixels = bytearray(SZ * SZ * 4)

# Fill: dark terminal background
for i in range(0, len(pixels), 4):
    pixels[i]   = 0x0E   # R
    pixels[i+1] = 0x0E   # G
    pixels[i+2] = 0x0E   # B
    pixels[i+3] = 0xFF   # A

def set_px(x, y, r, g, b, a=255):
    if 0 <= x < SZ and 0 <= y < SZ:
        off = (y * SZ + x) * 4
        pixels[off]   = r
        pixels[off+1] = g
        pixels[off+2] = b
        pixels[off+3] = a

def draw_circle(cx, cy, radius, r, g, b, a=255):
    \"\"\"Very rough circle — good enough for an icon.\"\"\"
    for dy in range(-radius, radius+1):
        dx = int(math.sqrt(max(0, radius*radius - dy*dy)))
        for x in range(cx-dx, cx+dx+1):
            set_px(x, cy+dy, r, g, b, a)

def draw_line(x1, y1, x2, y2, thickness, r, g, b, a=255):
    \"\"\"Thick line with sqrt distance.\"\"\"
    steps = max(abs(x2-x1), abs(y2-y1)) * 2
    for i in range(steps+1):
        t = i / steps
        cx = int(x1 + (x2-x1)*t)
        cy = int(y1 + (y2-y1)*t)
        draw_circle(cx, cy, thickness//2, r, g, b, a)

# White outer ring
ring_r = int(SZ * 0.35)
ring_thick = int(SZ * 0.04)
cx, cy = SZ//2, SZ//2

# Draw outer circle (ring)
for dy in range(-ring_r, ring_r+1):
    dx = int(math.sqrt(max(0, ring_r*ring_r - dy*dy)))
    for x in range(cx-dx, cx+dx+1):
        dist = int(math.sqrt((x-cx)**2 + (cy+dy-cy)**2))
        if ring_r - ring_thick <= dist <= ring_r:
            set_px(x, cy+dy, 0xFF, 0xFF, 0xFF, 255)

# Draw checkmark inside (two strokes)
inner = int(ring_r * 0.55)
# Stem: bottom-left → center
stem_start = (cx - int(inner*0.7), cy + int(inner*0.05))
stem_mid   = (cx - int(inner*0.15), cy - int(inner*0.25))
stem_end   = (cx + int(inner*0.8), cy + int(inner*0.6))

thick = max(4, int(SZ * 0.055))

# First stroke: bottom-left → near center
draw_line(*stem_start, *stem_mid, thick, 0x33, 0xFF, 0x33, 255)
# Second stroke: near center → top-right
draw_line(*stem_mid, *stem_end, thick, 0x33, 0xFF, 0x33, 255)

# ---------- PNG writer ----------
def png_pack(chunk_type, data):
    c = chunk_type + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

signature = b'\\x89PNG\\r\\n\\x1a\\n'

# IHDR
ihdr = struct.pack('>IIBBBBB', SZ, SZ, 8, 6, 0, 0, 0)

# IDAT — raw scanlines with filter byte 0
raw = b''
for y in range(SZ):
    raw += b'\\x00'
    row_start = y * SZ * 4
    raw += bytes(pixels[row_start:row_start + SZ*4])

idat = zlib.compress(raw)

png = signature
png += png_pack(b'IHDR', ihdr)
png += png_pack(b'IDAT', idat)
png += png_pack(b'IEND', b'')

with open('$out', 'wb') as f:
    f.write(png)
print(f'  ✓ Fallback icon written → $out')
"
}

# =============================================================================
# Main
# =============================================================================
echo '==> Generating app icons…'
mkdir -p "$OUT_DIR"

# ---------- composite onto black background (for app icon) ----------
black_bg_icon() {
    local in="$1" out="$2"
    python3 -c "
import struct, zlib

with open('$in', 'rb') as f:
    png = f.read()
assert png[:8] == b'\\x89PNG\\r\\n\\x1a\\n'
pos = 8; width = height = bitd = coltype = 0
palette = []; idat = b''
while pos < len(png):
    L = struct.unpack('>I', png[pos:pos+4])[0]
    t = png[pos+4:pos+8]; pos += 8
    d = png[pos:pos+L]; pos += L
    if t == b'IHDR':
        width = struct.unpack('>I', d[0:4])[0]
        height = struct.unpack('>I', d[4:8])[0]
        bitd, coltype = d[8], d[9]
    elif t == b'PLTE':
        for i in range(0, len(d), 3):
            palette.append((d[i], d[i+1], d[i+2]))
    elif t == b'IDAT': idat += d
    elif t == b'IEND': break
    pos += 4

raw = bytearray(zlib.decompress(idat))
pixels = []

bpp = {0:1, 2:3, 3:1, 4:2, 6:4}[coltype]
row_len = width * bpp + 1  # +1 for filter byte
for y in range(height):
    row_start = y * row_len + 1  # skip filter byte
    for x in range(width):
        if coltype == 0:       # Grayscale
            v = raw[row_start + x]; r = g = b = v; a = 255
        elif coltype == 2:     # RGB
            o = row_start + x*3; r, g, b = raw[o], raw[o+1], raw[o+2]; a = 255
        elif coltype == 3:     # Indexed
            idx = raw[row_start + x]
            r, g, b = palette[idx] if idx < len(palette) else (0, 0, 0); a = 255
        elif coltype == 4:     # Gray+Alpha
            o = row_start + x*2; r = g = b = raw[o]; a = raw[o+1]
        elif coltype == 6:     # RGBA
            o = row_start + x*4; r, g, b, a = raw[o], raw[o+1], raw[o+2], raw[o+3]
        else:
            r = g = b = 0; a = 255
        # Transparency → fill with black
        if a < 255:
            r, g, b, a = 0, 0, 0, 255
        pixels.append((r, g, b, a))

# Output RGBA
out_raw = b''
for y in range(height):
    out_raw += b'\\x00'
    for x in range(width):
        r, g, b, a = pixels[y*width + x]
        out_raw += bytes([r, g, b, a])

def pk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

with open('$out', 'wb') as f:
    f.write(b'\\x89PNG\\r\\n\\x1a\\n')
    f.write(pk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)))
    f.write(pk(b'IDAT', zlib.compress(out_raw)))
    f.write(pk(b'IEND', b''))
print('  ✓ Black bg composited (type ' + str(coltype) + ')')
"
}

# Determine source: user-provided icon.png or fallback
BASE_1024="$OUT_DIR/icon-1024@1x.png"

if [ -f "$SRC_ICON" ]; then
    src_w=$(sips -g pixelWidth  "$SRC_ICON" 2>/dev/null | awk '/pixelWidth/ {print $2}')
    src_h=$(sips -g pixelHeight "$SRC_ICON" 2>/dev/null | awk '/pixelHeight/ {print $2}')
    echo "  → Using user-provided icon: $SRC_ICON (${src_w}×${src_h})"
    # Composite onto black for app icon
    ICON_BLACK="${SRC_ICON%.png}-black.png"
    black_bg_icon "$SRC_ICON" "$ICON_BLACK"
    resize "$ICON_BLACK" "$BASE_1024" 1024
else
    echo "  → No $SRC_ICON found — generating fallback"
    generate_fallback "$BASE_1024" 1024
fi

# ---------- resize to all required dimensions ----------
# bash 3.2 compat: "name size" pairs, not associative array
SIZES="
icon-20@2x.png 40
icon-20@3x.png 60
icon-29@2x.png 58
icon-29@3x.png 87
icon-40@2x.png 80
icon-40@3x.png 120
icon-60@2x.png 120
icon-60@3x.png 180
icon-76@1x.png 76
icon-76@2x.png 152
icon-83.5@2x.png 167
"

echo "$SIZES" | while read -r fname size; do
    [ -z "$fname" ] && continue
    out="$OUT_DIR/$fname"
    echo "  → $fname (${size}×${size})"
    if ! resize "$BASE_1024" "$out" "$size"; then
        echo "  ✗ FAILED to resize $fname — retrying…"
        resize "$BASE_1024" "$out" "$size" || {
            echo "  ✗ FATAL: cannot generate $fname"; exit 1;
        }
    fi
    [ -s "$out" ] || { echo "  ✗ FATAL: $fname is empty"; exit 1; }
done

# 1024 is already done
echo "  → icon-1024@1x.png (1024×1024) — done"

echo ''
echo '==> Verifying generated icons…'
count=$(ls -1 "$OUT_DIR"/icon-*.png 2>/dev/null | wc -l | tr -d ' ')
echo "  → $count icon files found:"
ls -lh "$OUT_DIR"/icon-*.png 2>/dev/null | while read -r ln; do echo "     $ln"; done

if [ "$count" -lt 10 ]; then
    echo "  ✗ FATAL: expected ≥10 icon files, got $count"
    exit 1
fi

# ---------- copy logo for in-app use (into asset catalog) ----------
echo ''
echo '==> Preparing in-app logo…'
LOGO_DIR="$SRCROOT/Resources/Assets.xcassets/Logo.imageset"
LOGO_DST="$LOGO_DIR/logo.png"
mkdir -p "$LOGO_DIR"
if [ -f "$SRC_ICON" ]; then
    # In-app logo keeps transparency (original file)
    cp "$SRC_ICON" "$LOGO_DST"
    echo "  → Copied transparent icon → Logo.imageset/logo.png"
else
    cp "$BASE_1024" "$LOGO_DST"
    echo "  → Copied fallback icon → Logo.imageset/logo.png"
fi

# Also copy to Resources/ for bundle loading
cp "$LOGO_DST" "$SRCROOT/Resources/logo.png"

# ---------- copy package manager icons ----------
echo ''
echo '==> Copying package manager icons…'
for pm in sileo cydia zebra; do
    PM_SRC="$SRCROOT/icons/$pm.png"
    PM_DST="$SRCROOT/Resources/$pm.png"
    if [ -f "$PM_SRC" ]; then
        cp "$PM_SRC" "$PM_DST"
        echo "  → $pm.png → Resources/"
    else
        echo "  → $pm.png not found — skipping (will use fallback)"
    fi
done

echo '==> Icons generated successfully!'
