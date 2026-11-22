#!/usr/bin/env python3
"""Generates the app icon in every size from one geometry.

The icon (owner's sketch, 2026-11-22): a slanted „A” – as in TestAcer – drawn
with three bars. A green check mark (a right answer) and a green–blue cross
(an X) make the left leg and the crossbar; a red bar is the right leg. White
background.

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

GREEN = '#3FA34D'
BLUE = '#1F6FC4'
RED = '#D9483B'
BACKGROUND = '#FFFFFF'

# Geometry of the mark (any units; it is fitted to each canvas).
WIDTH = 108                 # bar width
APEX = (760.0, 150.0)       # top of the „A” (centre of the right leg)
TOP = 118.0                 # flat top of the apex
BASE = 880.0                # baseline
FOOT = (230.0, BASE)        # bottom of the left leg
VERTEX = 0.42               # where the check's corner sits on the left leg
CROSS_ANGLE = 33.0          # crossbar slope, degrees below horizontal
SHORT_ARM = 300.0           # the check's short stroke


def _bar(start, end, width):
    """Rectangle from start to end (centre line), as a polygon."""
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * width / 2, dx / length * width / 2
    return [
        (start[0] + nx, start[1] + ny),
        (end[0] + nx, end[1] + ny),
        (end[0] - nx, end[1] - ny),
        (start[0] - nx, start[1] - ny),
    ]


def _arm(centre, end, width):
    """A bar from a little behind [centre] to [end], so arms meet cleanly."""
    dx, dy = end[0] - centre[0], end[1] - centre[1]
    length = math.hypot(dx, dy)
    back = (centre[0] - dx / length * width / 2, centre[1] - dy / length * width / 2)
    return _bar(back, end, width)


def _clip(polygon, xmin, ymin, xmax, ymax):
    """Sutherland–Hodgman clipping to an axis-aligned rectangle."""
    def clip_edge(points, inside, intersect):
        out = []
        for i, current in enumerate(points):
            previous = points[i - 1]
            if inside(current):
                if not inside(previous):
                    out.append(intersect(previous, current))
                out.append(current)
            elif inside(previous):
                out.append(intersect(previous, current))
        return out

    def at_x(x):
        return lambda p, q: (x, p[1] + (q[1] - p[1]) * (x - p[0]) / (q[0] - p[0]))

    def at_y(y):
        return lambda p, q: (p[0] + (q[0] - p[0]) * (y - p[1]) / (q[1] - p[1]), y)

    points = polygon
    for inside, intersect in (
        (lambda p: p[0] >= xmin, at_x(xmin)),
        (lambda p: p[0] <= xmax, at_x(xmax)),
        (lambda p: p[1] >= ymin, at_y(ymin)),
        (lambda p: p[1] <= ymax, at_y(ymax)),
    ):
        points = clip_edge(points, inside, intersect)
        if not points:
            break
    return points


def mark_shapes():
    """The mark as (colour, polygon) pairs, bottom layer first."""
    w = WIDTH
    leg = (APEX[0] - FOOT[0], APEX[1] - FOOT[1])
    n = math.hypot(*leg)
    u = (leg[0] / n, leg[1] / n)
    vertex = (FOOT[0] + VERTEX * leg[0], FOOT[1] + VERTEX * leg[1])
    a = math.radians(CROSS_ANGLE)
    cross_end = (APEX[0], vertex[1] + (APEX[0] - vertex[0]) * math.tan(a))
    short_end = (vertex[0] - SHORT_ARM * math.cos(a), vertex[1] - SHORT_ARM * math.sin(a))
    past_apex = (APEX[0] + u[0] * w * 1.5, APEX[1] + u[1] * w * 1.5)
    past_foot = (FOOT[0] - u[0] * w, FOOT[1] - u[1] * w)
    right = APEX[0] + w / 2
    shapes = [
        (BLUE, _arm(vertex, past_foot, w)),         # left leg, lower part
        (BLUE, _arm(vertex, cross_end, w)),         # crossbar, right part
        (RED, _bar((APEX[0], TOP), (APEX[0], BASE), w)),  # right leg
        (GREEN, _arm(vertex, short_end, w)),        # check: short stroke
        (GREEN, _arm(vertex, past_apex, w)),        # check: long stroke
    ]
    # Flat top at the apex, straight baseline, nothing right of the red leg.
    return [(c, _clip(p, -1e9, TOP, right, BASE)) for c, p in shapes]


def fitted(shapes, size, *, fill=None, radius=None):
    """Scales and centres the shapes in a size × size canvas: the bounding
    box's longer side becomes [fill] × size, or every point stays within
    [radius] × size of the centre (adaptive / maskable safe zones)."""
    xs = [x for _, p in shapes for x, _ in p]
    ys = [y for _, p in shapes for _, y in p]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    if fill is not None:
        scale = fill * size / max(max(xs) - min(xs), max(ys) - min(ys))
    else:
        far = max(math.hypot(x - cx, y - cy) for _, p in shapes for x, y in p)
        scale = radius * size / far
    return [
        (c, [((x - cx) * scale + size / 2, (y - cy) * scale + size / 2) for x, y in p])
        for c, p in shapes
    ]


def polygons_svg(shapes, colour=None):
    return ''.join(
        f'<polygon fill="{colour or c}" points="'
        + ' '.join(f'{x:.2f},{y:.2f}' for x, y in p)
        + '"/>'
        for c, p in shapes
    )


def svg(body, size=1024):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" '
        f'width="{size}" height="{size}">{body}</svg>'
    )


def background(rounded):
    rx = ' rx="225"' if rounded else ''
    return f'<rect width="1024" height="1024"{rx} fill="{BACKGROUND}"/>'


# Variants ------------------------------------------------------------------

# Android adaptive icons: 108 dp canvas, content safe within a 66 dp circle.
ADAPTIVE_RADIUS = 0.30
# Web maskable icons: content safe within a circle of 80 % of the size.
MASKABLE_RADIUS = 0.36


def full_icon(rounded=True):
    """Square icon (legacy launcher, Play, web): background + mark."""
    return svg(background(rounded) + polygons_svg(fitted(mark_shapes(), 1024, fill=0.68)))


def maskable_icon():
    shapes = fitted(mark_shapes(), 1024, radius=MASKABLE_RADIUS)
    return svg(background(False) + polygons_svg(shapes))


def adaptive_background():
    return svg(background(False))


def adaptive_foreground():
    return svg(polygons_svg(fitted(mark_shapes(), 1024, radius=ADAPTIVE_RADIUS)))


def adaptive_monochrome():
    """Android 13 themed icon: only the alpha counts."""
    shapes = fitted(mark_shapes(), 1024, radius=ADAPTIVE_RADIUS)
    return svg(polygons_svg(shapes, colour='#000000'))


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
    shapes = fitted(mark_shapes(), 24, fill=21 / 24)
    paths = ''.join(
        '    <path android:fillColor="#FFFFFFFF" android:pathData="M'
        + ' L'.join(f'{x:.3f},{y:.3f}' for x, y in p)
        + ' Z"/>\n'
        for _, p in shapes
    )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Status-bar icon of the reminders: the app icon\'s „A” mark,\n'
        '     white on transparent as Android requires (tool/branding/make_icons.py). -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="24dp"\n'
        '    android:height="24dp"\n'
        '    android:viewportWidth="24"\n'
        '    android:viewportHeight="24">\n'
        + paths
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
        save(render(maskable_icon(), size), 'web', 'icons', f'Icon-maskable-{size}.png')
    save(render(full_icon(), 32), 'web', 'favicon.png')


if __name__ == '__main__':
    main()
