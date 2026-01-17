import json
import sys
from pathlib import Path
import cv2
import numpy as np

# Usage: python detect_draft.py screenshot.png
# Prereq: pip install opencv-python
# Templates: place hero icons (e.g., npc_dota_hero_axe.png) in templates/heroes/
# Coords file: templates/coords_1366x768.json (edit if precisar ajustar)

THIS_DIR = Path(__file__).parent
COORDS_FILE = THIS_DIR / "templates" / "coords_1366x768.json"
TEMPLATES_DIR = THIS_DIR / "templates" / "heroes"

MATCH_THRESHOLD = 0.7  # ajuste se necessário


def load_coords():
    with COORDS_FILE.open("r", encoding="utf-8") as f:
        return json.load(f)


def load_templates():
    templates = {}
    for png in TEMPLATES_DIR.glob("*.png"):
        img = cv2.imread(str(png), cv2.IMREAD_GRAYSCALE)
        if img is None:
            continue
        hero = png.stem  # espera nome tipo npc_dota_hero_axe
        templates[hero] = img
    return templates


def match_slot(slot_img, templates):
    best = None
    slot_gray = cv2.cvtColor(slot_img, cv2.COLOR_BGR2GRAY)
    for hero, tpl in templates.items():
        if tpl.shape[0] > slot_gray.shape[0] or tpl.shape[1] > slot_gray.shape[1]:
            continue
        res = cv2.matchTemplate(slot_gray, tpl, cv2.TM_CCOEFF_NORMED)
        _, max_val, _, _ = cv2.minMaxLoc(res)
        if best is None or max_val > best[1]:
            best = (hero, max_val)
    if best and best[1] >= MATCH_THRESHOLD:
        return best[0], float(best[1])
    return None, None


def main():
    if len(sys.argv) < 2:
        print("Usage: python detect_draft.py screenshot.png", file=sys.stderr)
        sys.exit(1)
    screenshot_path = Path(sys.argv[1])
    img = cv2.imread(str(screenshot_path))
    if img is None:
        print("Cannot read screenshot", file=sys.stderr)
        sys.exit(1)

    coords = load_coords()
    templates = load_templates()
    if not templates:
        print("No templates found in templates/heroes", file=sys.stderr)
        sys.exit(1)

    result = {"radiant": [], "dire": []}

    for side in ("radiant", "dire"):
        for slot in coords.get(side, []):
            x, y, w, h = slot["x"], slot["y"], slot["w"], slot["h"]
            crop = img[y:y+h, x:x+w]
            hero, score = match_slot(crop, templates)
            if hero:
                result[side].append({"hero": hero, "score": score})
            else:
                result[side].append({"hero": None, "score": 0.0})

    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
