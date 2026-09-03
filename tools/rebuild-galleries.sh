#!/usr/bin/env python3
"""
rebuild-galleries.sh — Phoenix Conexus gallery rebuilder
Run this script whenever you add or remove images from a Graphics subfolder.
It rescans each folder and rewrites the img-grid sections in the HTML files.

Usage:
    python3 rebuild-galleries.sh
    (or: chmod +x rebuild-galleries.sh && ./rebuild-galleries.sh)

Place this file at: ~/server/www/phoenix-conexus/tools/rebuild-galleries.sh
"""

import os
import re
import sys

# ── CONFIG ──────────────────────────────────────────────────────────────────
SITE_ROOT = os.path.expanduser('~/server/www/phoenix-conexus')
GRAPHICS   = os.path.join(SITE_ROOT, 'Graphics')
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg',
              '.JPG', '.JPEG', '.PNG', '.GIF', '.WEBP'}

# Maps each HTML file to the gallery folders it contains, in order.
# Key   = HTML filename (relative to SITE_ROOT)
# Value = list of Graphics subfolders (relative to GRAPHICS root)
GALLERIES = {
    'telecom.html': [
        'Telecom/Engineering',
        'Telecom/In-Building DAS',
        'Telecom/Planning',
        'Telecom/Project Management',
        'Telecom/Survey',
    ],
    'architecture.html': [
        'Architecture/2D & 3D Rendering',
        'Architecture/Engineering',
        'Architecture/Survey',
    ],
    '3d-design.html': [
        '3D Design/Industial',
        '3D Design/Modelling',
        '3D Design/Plan and Build',
        '3D Design/Prototype and Print',
    ],
}

# ── HELPERS ─────────────────────────────────────────────────────────────────
def make_alt(filename):
    """Generate a readable alt text from a filename."""
    name = os.path.splitext(filename)[0]
    # Strip common prefixes like "Telecom_Engineering_", "3D_Plan and Build_"
    name = re.sub(r'^[^_]+_[^_]+_', '', name)
    # Replace hyphens/underscores with spaces, clean up
    name = name.replace('-', ' ').replace('_', ' ')
    name = re.sub(r'\s+', ' ', name).strip()
    return name


def build_img_grid(folder_rel):
    """Scan a folder and return the img-grid HTML block."""
    folder_abs = os.path.join(GRAPHICS, folder_rel)

    if not os.path.isdir(folder_abs):
        print(f'  WARNING: folder not found: {folder_abs}')
        return None

    files = sorted([
        f for f in os.listdir(folder_abs)
        if os.path.splitext(f)[1] in IMAGE_EXTS
    ])

    if not files:
        print(f'  WARNING: no images found in: {folder_abs}')
        return None

    lines = ['      <div class="img-grid img-grid-5">']
    for fname in files:
        # URL-encode spaces in the path for the src attribute
        src_path = f'Graphics/{folder_rel}/{fname}'.replace(' ', '%20')
        alt = make_alt(fname)
        lines.append(
            f'        <div class="img-frame">'
            f'<img src="{src_path}" alt="{alt}" loading="lazy">'
            f'</div>'
        )
    lines.append('      </div>')
    return '\n'.join(lines)


def rebuild_file(html_file, folders):
    """Rebuild all gallery sections in one HTML file."""
    html_path = os.path.join(SITE_ROOT, html_file)

    if not os.path.isfile(html_path):
        print(f'SKIP: {html_file} not found at {html_path}')
        return

    with open(html_path, 'r', encoding='utf-8') as fh:
        content = fh.read()

    original = content

    # Each gallery-section contains exactly one img-grid.
    # We find each gallery-section block and match it to a folder
    # by order of appearance — the nth gallery-section corresponds
    # to the nth folder in the GALLERIES list.
    gallery_pattern = re.compile(
        r'(<div class="gallery-section reveal">\s*)'   # opening
        r'(<div class="img-grid img-grid-\d+">'        # grid open
        r'.*?'                                          # existing items
        r'</div>)'                                      # grid close
        r'(\s*</div>)',                                 # gallery-section close
        re.DOTALL
    )

    matches = list(gallery_pattern.finditer(content))

    if len(matches) != len(folders):
        print(f'  WARNING: {html_file} has {len(matches)} gallery sections '
              f'but config lists {len(folders)} folders — skipping.')
        return

    # Build replacements in reverse order so string positions stay valid
    for match, folder in reversed(list(zip(matches, folders))):
        new_grid = build_img_grid(folder)
        if new_grid is None:
            continue

        replacement = match.group(1) + new_grid + match.group(3)
        content = content[:match.start()] + replacement + content[match.end():]
        print(f'  ✓  {folder}')

    if content != original:
        with open(html_path, 'w', encoding='utf-8') as fh:
            fh.write(content)
        print(f'  → {html_file} updated.')
    else:
        print(f'  → {html_file} unchanged.')


# ── MAIN ────────────────────────────────────────────────────────────────────
def main():
    print(f'\nPhoenix Conexus — Gallery Rebuilder')
    print(f'Site root : {SITE_ROOT}')
    print(f'Graphics  : {GRAPHICS}\n')

    if not os.path.isdir(SITE_ROOT):
        print(f'ERROR: Site root not found: {SITE_ROOT}')
        sys.exit(1)

    for html_file, folders in GALLERIES.items():
        print(f'Processing {html_file}:')
        rebuild_file(html_file, folders)
        print()

    print('Done.')


if __name__ == '__main__':
    main()
