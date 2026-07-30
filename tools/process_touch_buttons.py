from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\Aron Domżała\.cursor\projects\c-Users-Aron-Dom-a-a-Aria-Horse-Game"
    r"\assets\c__Users_Aron_Dom_a_a_AppData_Roaming_Cursor_User_workspaceStorage"
    r"_empty-window_images_butt-37720bb0-07dc-4b02-bc07-96e1700c5142.png"
)
DST = Path(r"C:\Users\Aron Domżała\Aria Horse Game\assets\ui")
BG_THRESH = 10
ALPHA_MIN = 8
PAD = 2


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


if __name__ == "__main__":
    im = Image.open(SRC).convert("RGBA")
    w, h = im.size
    halves = {
        "btn_run": im.crop((0, 0, w // 2, h)),
        "btn_jump": im.crop((w // 2, 0, w, h)),
    }
    DST.mkdir(parents=True, exist_ok=True)
    for name, half in halves.items():
        out = trim(key_black_to_alpha(half))
        out.save(DST / f"{name}.png")
        print(f"{name}: {out.size}")
    print("done")
