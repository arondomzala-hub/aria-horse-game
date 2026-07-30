from PIL import Image
from pathlib import Path

ENV = Path(r"C:\Users\Aron Domżała\Aria Horse Game\assets\env")
BG_THRESH = 22

# grass is a full opaque tile — do not key black
KEY_BLACK = {
    "mountain_snow_large.png",
    "mountain_dark_large.png",
    "mountain_dark_medium.png",
    "pine_large.png",
    "pine_medium.png",
    "pine_small.png",
    "hay_bale.png",
}


def process(name: str, key_black: bool) -> None:
    path = ENV / name
    im = Image.open(path).convert("RGBA")
    print(f"{name}: in={im.size} format_hint header")
    if key_black:
        px = im.load()
        w, h = im.size
        for y in range(h):
            for x in range(w):
                r, g, b, _a = px[x, y]
                if r <= BG_THRESH and g <= BG_THRESH and b <= BG_THRESH:
                    px[x, y] = (0, 0, 0, 0)
        # trim to opaque bbox + pad
        minx, miny, maxx, maxy = w, h, -1, -1
        for y in range(h):
            for x in range(w):
                if px[x, y][3] > 8:
                    minx = min(minx, x)
                    miny = min(miny, y)
                    maxx = max(maxx, x)
                    maxy = max(maxy, y)
        if maxx >= 0:
            pad = 4
            crop = (
                max(0, minx - pad),
                max(0, miny - pad),
                min(w, maxx + 1 + pad),
                min(h, maxy + 1 + pad),
            )
            im = im.crop(crop)
    im.save(path, optimize=False)
    print(f"  -> out={im.size}")


if __name__ == "__main__":
    for p in sorted(ENV.glob("*.png")):
        process(p.name, p.name in KEY_BLACK)
    print("done")
