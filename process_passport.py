#!/usr/bin/env python3
"""
Passport photo processor:
- Sharpens edges significantly
- Expands top by 6mm (white background)
- Expands bottom by 9mm (white background)
- Replaces grey background with white (using HSV saturation + flood fill)
"""

import cv2
import numpy as np
from PIL import Image
import sys
import os


def get_dpi(image_path):
    """Get DPI from image metadata, default to 300."""
    try:
        img_pil = Image.open(image_path)
        if 'dpi' in img_pil.info:
            dpi = img_pil.info['dpi']
            if isinstance(dpi, tuple):
                return int(dpi[0])
            return int(dpi)
    except Exception:
        pass
    return 300


def remove_grey_background(img):
    """
    Replace grey/white background with pure white.
    Uses HSV saturation to distinguish achromatic background
    (grey/white) from skin and hair, then flood fills from borders.
    """
    h, w = img.shape[:2]

    # Convert to HSV
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    saturation = hsv[:, :, 1]   # 0-255, 0 = grey/white
    value = hsv[:, :, 2]        # 0-255, brightness

    # Candidate background: low saturation (grey/white) and not too dark
    # Saturation < 30 means nearly achromatic (grey/white)
    # Value > 140 excludes very dark pixels (hair etc.)
    candidate_bg = ((saturation < 30) & (value > 140)).astype(np.uint8) * 255

    # Now flood fill from borders to get only border-connected background
    # Build a mask image where candidate pixels = 128 (fillable), rest = 255 (barrier)
    fill_img = np.where(candidate_bg[:, :, np.newaxis] == 255,
                        np.array([128, 128, 128], dtype=np.uint8),
                        np.array([0, 0, 0], dtype=np.uint8)).astype(np.uint8)

    mask = np.zeros((h + 2, w + 2), np.uint8)

    seed_points = []
    for x in range(0, w, 3):
        seed_points.append((x, 0))
        seed_points.append((x, h - 1))
    for y in range(0, h, 3):
        seed_points.append((0, y))
        seed_points.append((w - 1, y))

    for (x, y) in seed_points:
        px = fill_img[y, x, 0]
        if px == 128 and mask[y + 1, x + 1] == 0:
            cv2.floodFill(fill_img, mask, (x, y), (200, 200, 200),
                          loDiff=(80, 80, 80), upDiff=(80, 80, 80))

    background_mask = (fill_img[:, :, 0] == 200)

    # Slightly dilate mask to capture fringe pixels around hair
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    background_mask_dilated = cv2.dilate(background_mask.astype(np.uint8), kernel, iterations=1).astype(bool)

    # Only apply to pixels that are still grey/white after dilation
    # (don't overwrite dark hair pixels in fringe)
    apply_mask = background_mask_dilated & (saturation < 45) & (value > 120)

    result = img.copy()
    result[apply_mask] = [255, 255, 255]
    return result


def sharpen_strong(img):
    """Apply strong sharpening using multi-pass unsharp masking."""
    # Pass 1: fine detail (sigma=0.8)
    gaussian1 = cv2.GaussianBlur(img.astype(np.float32), (0, 0), 0.8)
    sharp1 = cv2.addWeighted(img.astype(np.float32), 1.6, gaussian1, -0.6, 0)
    sharp1 = np.clip(sharp1, 0, 255).astype(np.uint8)

    # Pass 2: medium detail (sigma=1.5)
    gaussian2 = cv2.GaussianBlur(sharp1.astype(np.float32), (0, 0), 1.5)
    sharp2 = cv2.addWeighted(sharp1.astype(np.float32), 1.4, gaussian2, -0.4, 0)
    sharp2 = np.clip(sharp2, 0, 255).astype(np.uint8)

    return sharp2


def process_passport_photo(input_path, output_path, dpi=None):
    if not os.path.exists(input_path):
        print(f"Error: File not found: {input_path}")
        sys.exit(1)

    if dpi is None:
        dpi = get_dpi(input_path)

    print(f"Using DPI: {dpi}")

    mm_per_inch = 25.4
    top_px = int(round(6.0 * dpi / mm_per_inch))    # 6mm above hair
    bottom_px = int(round(9.0 * dpi / mm_per_inch))  # 9mm below chin

    print(f"Top expansion:    {top_px}px  ({6}mm at {dpi}dpi)")
    print(f"Bottom expansion: {bottom_px}px ({9}mm at {dpi}dpi)")

    img = cv2.imread(input_path)
    if img is None:
        print(f"Error: Could not load image: {input_path}")
        sys.exit(1)

    h, w = img.shape[:2]
    print(f"Original size: {w}x{h}px")

    # Step 1: Replace grey background with white
    print("Removing grey background...")
    img = remove_grey_background(img)

    # Step 2: Sharpen strongly
    print("Sharpening edges...")
    img = sharpen_strong(img)

    # Step 3: Expand top and bottom with white
    print("Expanding image...")
    white_top = np.full((top_px, w, 3), 255, dtype=np.uint8)
    white_bottom = np.full((bottom_px, w, 3), 255, dtype=np.uint8)
    result = np.vstack([white_top, img, white_bottom])

    new_h = result.shape[0]
    print(f"New size: {w}x{new_h}px")

    # Save using Pillow to preserve DPI metadata
    result_rgb = cv2.cvtColor(result, cv2.COLOR_BGR2RGB)
    result_pil = Image.fromarray(result_rgb)
    result_pil.save(output_path, dpi=(dpi, dpi))

    print(f"Saved: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 process_passport.py <input> <output> [dpi]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    dpi = int(sys.argv[3]) if len(sys.argv) > 3 else None

    process_passport_photo(input_path, output_path, dpi)
