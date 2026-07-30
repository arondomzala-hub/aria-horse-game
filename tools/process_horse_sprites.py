from collections import deque
from pathlib import Path

from PIL import Image

DST = Path(r"C:\Users\Aron Domżała\Aria Horse Game\assets\horses")
SRC = Path(r"C:\Users\Aron Domżała\Aria Horse Game\tools\source")
GRID_COLS = 3
GRID_ROWS = 2
FRAMES = GRID_COLS * GRID_ROWS
BG_THRESH = 10
ALPHA_MIN = 8
PAD = 2
# Detached wisps (mane/tail) closer than this to a horse get attached to it.
ATTACH_DIST = 30


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def key_black_to_alpha(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _a = px[x, y]
            if r <= BG_THRESH and g <= BG_THRESH and b <= BG_THRESH:
                px[x, y] = (0, 0, 0, 0)
    return im


def label_components(im: Image.Image):
    """8-connected components of opaque pixels. Returns (labels, comps) where
    labels maps (x, y) -> component id and comps is {id: [pixels...]}."""
    px = im.load()
    w, h = im.size
    labels = {}
    comps = {}
    next_id = 0
    for sy in range(h):
        for sx in range(w):
            if px[sx, sy][3] < ALPHA_MIN or (sx, sy) in labels:
                continue
            comp = []
            queue = deque([(sx, sy)])
            labels[(sx, sy)] = next_id
            while queue:
                x, y = queue.popleft()
                comp.append((x, y))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in labels \
                                and px[nx, ny][3] >= ALPHA_MIN:
                            labels[(nx, ny)] = next_id
                            queue.append((nx, ny))
            comps[next_id] = comp
            next_id += 1
    return comps


def bbox_of(pixels):
    xs = [p[0] for p in pixels]
    ys = [p[1] for p in pixels]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


def bbox_dist(a, b):
    """Gap between two bboxes (0 if they overlap)."""
    dx = max(a[0] - b[2], b[0] - a[2], 0)
    dy = max(a[1] - b[3], b[1] - a[3], 0)
    return max(dx, dy)


def extract_horses(im: Image.Image):
    """Find the FRAMES largest components (the horses), attach nearby small
    wisps (detached mane/tail), drop far-away noise. Returns a list of pixel
    groups ordered row-major by centroid (top row left-to-right first)."""
    comps = label_components(im)
    by_size = sorted(comps.values(), key=len, reverse=True)
    assert len(by_size) >= FRAMES, f"expected >= {FRAMES} components, got {len(by_size)}"
    horses = [list(c) for c in by_size[:FRAMES]]
    horse_boxes = [bbox_of(c) for c in horses]

    attached = dropped = 0
    for comp in by_size[FRAMES:]:
        cbox = bbox_of(comp)
        dists = [bbox_dist(cbox, hb) for hb in horse_boxes]
        best = min(range(FRAMES), key=lambda i: dists[i])
        if dists[best] <= ATTACH_DIST:
            horses[best].extend(comp)
            attached += 1
        else:
            dropped += 1
    print(f"components: {len(by_size)} total, {attached} attached, {dropped} dropped")

    def centroid(pixels):
        n = len(pixels)
        return (sum(p[0] for p in pixels) / n, sum(p[1] for p in pixels) / n)

    h = im.size[1]
    cells = []
    for pixels in horses:
        cx, cy = centroid(pixels)
        row = 0 if cy < h / 2 else 1
        cells.append((row, cx, pixels))
    cells.sort(key=lambda t: (t[0], t[1]))
    return [t[2] for t in cells]


def render_frames(im: Image.Image, groups):
    """Copy each horse's own pixels onto per-frame canvases of equal size,
    anchored bottom-center so hooves stay level across the cycle."""
    src = im.load()
    cutouts = []
    for pixels in groups:
        x0, y0, x1, y1 = bbox_of(pixels)
        x0, y0 = x0 - PAD, y0 - PAD
        x1, y1 = x1 + PAD, y1 + PAD
        cut = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        cpx = cut.load()
        for x, y in pixels:
            cpx[x - x0, y - y0] = src[x, y]
        cutouts.append(cut)

    max_w = max(c.size[0] for c in cutouts)
    max_h = max(c.size[1] for c in cutouts)
    frames = []
    for cut in cutouts:
        canvas = Image.new("RGBA", (max_w, max_h), (0, 0, 0, 0))
        canvas.paste(cut, ((max_w - cut.size[0]) // 2, max_h - cut.size[1]), cut)
        frames.append(canvas)
    return frames


def sheet_from_frames(frames):
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * w, 0), fr)
    return sheet


def process(name: str):
    src = SRC / f"{name}.png"
    if not src.exists():
        src = SRC / f"{name}.jpg"
    im = key_black_to_alpha(load_rgba(src))
    groups = extract_horses(im)
    frames = render_frames(im, groups)
    frame_dir = DST / name
    frame_dir.mkdir(parents=True, exist_ok=True)
    for i, fr in enumerate(frames):
        fr.save(frame_dir / f"frame_{i:02d}.png")
    sheet = sheet_from_frames(frames)
    sheet.save(DST / f"{name}.png")
    print(f"{name}: sheet={sheet.size} frame={frames[0].size}")
    for i, g in enumerate(groups):
        print(f"  [{i}] pixels={len(g)} bbox={bbox_of(g)}")


if __name__ == "__main__":
    process("horse")
    print("done")
