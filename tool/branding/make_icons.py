#!/usr/bin/env python3
"""Generates the app icon in every size from one geometry.

The icon: a black judo belt whose two ends form a check mark (a right
answer), tied at the corner, on the app's blue (seed colour #1F3A93).

Needs `rsvg-convert` (librsvg) and Pillow. Run from the repository root:

    python3 tool/branding/make_icons.py

Writes:
  assets/branding/*.svg               sources (full icon, adaptive layers)
  assets/branding/play-icon-512.png   Google Play listing icon
  android/app/src/main/res/mipmap-*/  launcher icons (legacy + adaptive)
  android/app/src/main/res/drawable/ic_stat_reminder.xml  status-bar icon
  web/favicon.png, web/icons/*        web app icons
"""

import io
import math
import os
import subprocess

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BLUE_TOP = '#2A4DB3'
BLUE_BOTTOM = '#1A317F'
BLUE = '#1F3A93'
BELT = '#141414'
STITCH = '#4A4A4A'
OUTLINE = '#FFFFFF'

# Geometry on a 1024 × 1024 canvas, centred on (512, 512).
WIDTH = 118          # belt width
SHORT = (-135.0, 250)  # (angle in degrees, length) of the short end
LONG = (-46.6, 520)    # the long end
KNOT = 168           # knot size
OUTLINE_W = 30       # white rim around belt and knot


def _layout(scale=1.0):
    """Vertex position so that the whole mark is centred."""
    pts = [(0.0, 0.0)]
    for angle, length in (SHORT, LONG):
        a = math.radians(angle)
        pts.append((math.cos(a) * length, math.sin(a) * length))
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    cx = (min(xs) + max(xs)) / 2
    cy = (min(ys) + max(ys)) / 2
    return 512 - cx * scale, 512 - cy * scale + 18 * scale


def mark(scale=1.0, *, mono=False, outline=True):
    """SVG elements of the belt mark, scaled around the centre."""
    vx, vy = _layout(scale)
    w = WIDTH * scale
    k = KNOT * scale
    ow = OUTLINE_W * scale
    arms = []
    for angle, length in (SHORT, LONG):
        L = length * scale
        arms.append(
            f'<g transform="translate({vx:.1f} {vy:.1f}) rotate({angle})">'
            f'<rect x="{-w / 2:.1f}" y="{-w / 2:.1f}" width="{L + w / 2:.1f}" '
            f'height="{w:.1f}" rx="{w * 0.08:.1f}"/></g>'
        )
    knot_angle = LONG[0]
    # A bare <rect> (no <g>), so that it can also serve as a clip path.
    knot = (
        f'<rect transform="translate({vx:.1f} {vy:.1f}) rotate({knot_angle})" '
        f'x="{-k / 2:.1f}" y="{-k / 2:.1f}" width="{k:.1f}" '
        f'height="{k:.1f}" rx="{k * 0.16:.1f}"/>'
    )
    stitches = []
    for angle, length in (SHORT, LONG):
        L = length * scale
        for off in (-0.30, -0.10, 0.10, 0.30):
            y = off * w
            stitches.append(
                f'<g transform="translate({vx:.1f} {vy:.1f}) rotate({angle})">'
                f'<line x1="{k * 0.55:.1f}" y1="{y:.1f}" x2="{L - w * 0.22:.1f}" '
                f'y2="{y:.1f}"/></g>'
            )
    # The wrap across the knot, kept inside it.
    fold = (
        f'<g transform="translate({vx:.1f} {vy:.1f}) rotate({knot_angle + 90})">'
        f'<rect x="{-k:.1f}" y="{-k * 0.17:.1f}" width="{2 * k:.1f}" '
        f'height="{k * 0.34:.1f}"/></g>'
    )
    fold_edges = (
        f'<g transform="translate({vx:.1f} {vy:.1f}) rotate({knot_angle + 90})">'
        f'<line x1="{-k:.1f}" y1="{-k * 0.17:.1f}" x2="{k:.1f}" y2="{-k * 0.17:.1f}"/>'
        f'<line x1="{-k:.1f}" y1="{k * 0.17:.1f}" x2="{k:.1f}" y2="{k * 0.17:.1f}"/></g>'
    )
    if mono:
        # One colour (alpha only): the stitches and the knot's rim are cut out.
        return (
            '<defs><mask id="m">'
            f'<g fill="#fff">{"".join(arms)}</g>'
            f'<g fill="#000" stroke="#000" stroke-width="{ow * 1.2:.1f}">{knot}</g>'
            f'<g fill="#fff">{knot}</g>'
            f'<g stroke="#000" stroke-width="{9 * scale:.1f}" stroke-linecap="round">'
            f'{"".join(stitches)}</g>'
            '</mask></defs>'
            '<rect width="1024" height="1024" fill="#000" mask="url(#m)"/>'
        )
    parts = []
    if outline:
        parts.append(
            f'<g fill="{OUTLINE}" stroke="{OUTLINE}" stroke-width="{ow * 2:.1f}" '
            f'stroke-linejoin="round">{"".join(arms)}</g>'
        )
    parts.append(f'<g fill="{BELT}">{"".join(arms)}</g>')
    parts.append(
        f'<g stroke="{STITCH}" stroke-width="{8 * scale:.1f}" '
        f'stroke-linecap="round">{"".join(stitches)}</g>'
    )
    parts.append(
        f'<g fill="{BELT}" stroke="{OUTLINE}" stroke-width="{ow:.1f}" '
        f'paint-order="stroke">{knot}</g>'
    )
    parts.append(
        f'<defs><clipPath id="knot{int(scale * 100)}">{knot}</clipPath></defs>'
        f'<g clip-path="url(#knot{int(scale * 100)})">'
        f'<g fill="#2B2B2B">{fold}</g>'
        f'<g stroke="{STITCH}" stroke-width="{7 * scale:.1f}">{fold_edges}</g></g>'
    )
    return ''.join(parts)


def background(rounded):
    rx = ' rx="225"' if rounded else ''
    return (
        '<defs><linearGradient id="bg" x1="0" y1="0" x2="0.35" y2="1">'
        f'<stop offset="0" stop-color="{BLUE_TOP}"/>'
        f'<stop offset="1" stop-color="{BLUE_BOTTOM}"/>'
        '</linearGradient></defs>'
        f'<rect width="1024" height="1024"{rx} fill="url(#bg)"/>'
    )


def svg(body):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" '
        f'width="1024" height="1024">{body}</svg>'
    )


# Variants ------------------------------------------------------------------

def full_icon(rounded=True, scale=1.0):
    """Square icon (legacy launcher, Play, web): background + mark."""
    return svg(background(rounded) + mark(scale))


# Inside the 66 dp safe circle of the 108 dp adaptive canvas.
ADAPTIVE_SCALE = 0.74


def adaptive_background():
    return svg(background(False))


def adaptive_foreground():
    # 108 dp canvas; keep the mark inside the 66 dp safe circle.
    return svg(mark(ADAPTIVE_SCALE))


def adaptive_monochrome():
    return svg(mark(ADAPTIVE_SCALE, mono=True))


# Rendering -----------------------------------------------------------------

def render(svg_text, size):
    png = subprocess.run(
        ['rsvg-convert', '-w', str(size), '-h', str(size)],
        input=svg_text.encode(),
        capture_output=True,
        check=True,
    ).stdout
    return Image.open(io.BytesIO(png)).convert('RGBA')


def save(img, *path):
    full = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img.save(full, optimize=True)
    return full


def write(text, *path):
    full = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w', encoding='utf-8') as f:
        f.write(text)


DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def status_bar_icon():
    """24 dp white silhouette for the notification (VectorDrawable)."""
    s = 24 / 1024
    scale = 1.35  # fills about 21 of the 24 dp
    vx, vy = _layout(scale)
    vy -= 68  # the knot's corners make it look low; centre it optically
    w = WIDTH * scale * s
    k = KNOT * scale * s
    groups = []
    for angle, length in (SHORT, LONG):
        L = length * scale * s
        groups.append(
            f'    <group android:translateX="{vx * s:.3f}" android:translateY="{vy * s:.3f}" '
            f'android:rotation="{angle}">\n'
            f'        <path android:fillColor="#FFFFFFFF" android:pathData="'
            f'M{-w / 2:.3f},{-w / 2:.3f}h{L + w / 2:.3f}v{w:.3f}h{-(L + w / 2):.3f}z"/>\n'
            '    </group>\n'
        )
    groups.append(
        f'    <group android:translateX="{vx * s:.3f}" android:translateY="{vy * s:.3f}" '
        f'android:rotation="{LONG[0]}">\n'
        f'        <path android:fillColor="#FFFFFFFF" android:pathData="'
        f'M{-k / 2:.3f},{-k / 2:.3f}h{k:.3f}v{k:.3f}h{-k:.3f}z"/>\n'
        '    </group>\n'
    )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Status-bar icon of the reminders: the app icon\'s belt-check mark,\n'
        '     white on transparent as Android requires (tool/branding/make_icons.py). -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="24dp"\n'
        '    android:height="24dp"\n'
        '    android:viewportWidth="24"\n'
        '    android:viewportHeight="24">\n'
        + ''.join(groups)
        + '</vector>\n'
    )


ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
'''


def main():
    write(full_icon(), 'assets', 'branding', 'icon.svg')
    write(adaptive_background(), 'assets', 'branding', 'icon-background.svg')
    write(adaptive_foreground(), 'assets', 'branding', 'icon-foreground.svg')
    write(adaptive_monochrome(), 'assets', 'branding', 'icon-monochrome.svg')

    # Android launcher: legacy (rounded square) + adaptive layers (108 dp).
    res = ('android', 'app', 'src', 'main', 'res')
    for name, factor in DENSITIES.items():
        legacy = round(48 * factor)
        layer = round(108 * factor)
        save(render(full_icon(), legacy), *res, f'mipmap-{name}', 'ic_launcher.png')
        save(render(adaptive_background(), layer), *res, f'mipmap-{name}',
             'ic_launcher_background.png')
        save(render(adaptive_foreground(), layer), *res, f'mipmap-{name}',
             'ic_launcher_foreground.png')
        save(render(adaptive_monochrome(), layer), *res, f'mipmap-{name}',
             'ic_launcher_monochrome.png')
    write(ADAPTIVE_XML, *res, 'mipmap-anydpi-v26', 'ic_launcher.xml')
    write(status_bar_icon(), *res, 'drawable', 'ic_stat_reminder.xml')

    # Google Play listing: 512 × 512, full square (Play rounds the corners).
    save(render(full_icon(rounded=False), 512).convert('RGB'),
         'assets', 'branding', 'play-icon-512.png')

    # Web: "any" icons rounded; maskable ones full-bleed with a smaller mark.
    for size in (192, 512):
        save(render(full_icon(), size), 'web', 'icons', f'Icon-{size}.png')
        save(render(full_icon(rounded=False, scale=0.78), size),
             'web', 'icons', f'Icon-maskable-{size}.png')
    save(render(full_icon(), 32), 'web', 'favicon.png')


if __name__ == '__main__':
    main()
