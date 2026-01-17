import json
from pathlib import Path
import sys
import cv2

THIS_DIR = Path(__file__).parent
COORDS_FILE = THIS_DIR / "templates" / "coords_1366x768.json"


def main():
    if len(sys.argv) < 2:
        print("Usage: python crop_slots.py screenshot.png")
        sys.exit(1)
    img_path = Path(sys.argv[1])
    img = cv2.imread(str(img_path))
    if img is None:
        print("Cannot read image")
        sys.exit(1)
    with COORDS_FILE.open("r", encoding="utf-8") as f:
        coords = json.load(f)
    outdir = THIS_DIR / "slots"
    outdir.mkdir(exist_ok=True)
    idx = 0
    for side in ("radiant", "dire"):
        for slot in coords.get(side, []):
            x, y, w, h = slot["x"], slot["y"], slot["w"], slot["h"]
            crop = img[y:y+h, x:x+w]
            cv2.imwrite(str(outdir / f"{side}_{idx}.png"), crop)
            idx += 1
    print(f"Crops salvos em {outdir}")

if __name__ == "__main__":
    main()
