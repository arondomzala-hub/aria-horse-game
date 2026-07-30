from pathlib import Path

from PIL import Image

SRC = Path(r"C:\Users\Aron Domżała\Aria Horse Game\tools\source")
DST = Path(r"C:\Users\Aron Domżała\Aria Horse Game\assets\obstacles")
BG_THRESH = 10
ALPHA_MIN = 8
PAD = 2

NAMES = ["cross", "puddle", "fallen_tree"]


def key_black_to_alpha(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _a = px[x, y]
            if r <= BG_THRESH and g <= BG_THRESH and b <= BG_THRESH:
                px[x, y] = (0, 0, 0, 0)
    return im


def trim(im: Image.Image) -> Image.Image:
    alpha = im.getchannel("A").point(lambda a: 255 if a >= ALPHA_MIN else 0)
    bbox = alpha.getbbox()
    assert bbox, "empty image"
    x0 = max(0, bbox[0] - PAD)
    y0 = max(0, bbox[1] - PAD)
    x1 = min(im.size[0], bbox[2] + PAD)
    y1 = min(im.size[1], bbox[3] + PAD)
    return im.crop((x0, y0, x1, y1))


def process(name: str):
    im = Image.open(SRC / f"{name}.png").convert("RGBA")
    out = trim(key_black_to_alpha(im))
    DST.mkdir(parents=True, exist_ok=True)
    out.save(DST / f"{name}.png")
    print(f"{name}: {out.size}")


if __name__ == "__main__":
    for n in NAMES:
        process(n)
    print("done")
