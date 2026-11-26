"""Record assets/demo.sh into assets/demo.gif: replay its output in pyte, render frames via rsvg-convert, join with ffmpeg.
usage (needs pyte, rsvg-convert, ffmpeg): python3 assets/record.py assets/demo.sh assets/demo.gif /tmp/frames"""
import os, subprocess, sys, time, html, pyte

script, out, wd = sys.argv[1:4]
COLS, ROWS, FPS = 102, 29, 12
CW, CH, PAD = 9.0, 19, 18
BG, FG = "#030a05", "#39ff14"

# 1. record (t, bytes)
p = subprocess.Popen(["bash", script], stdout=subprocess.PIPE)
t0, chunks = time.time(), []
while True:
    b = os.read(p.stdout.fileno(), 65536)
    if not b: break
    chunks.append((time.time() - t0, b))
p.wait()
end = time.time() - t0

# 2. replay into a virtual screen, snapshot at each frame time
screen = pyte.Screen(COLS, ROWS); stream = pyte.ByteStream(screen)
os.makedirs(wd, exist_ok=True)
W, H = int(COLS * CW + 2 * PAD), int(ROWS * CH + 2 * PAD)
def color(c, default):
    if c == "default": return default
    if len(c) == 6 and all(x in "0123456789abcdefABCDEF" for x in c): return "#" + c
    return default
def svg_frame():
    rows = []
    for y in range(ROWS):
        line = screen.buffer[y]; spans, cur, txt = [], None, ""
        for x in range(COLS):
            ch = line[x]; key = (color(ch.fg, FG), ch.bold)
            if key != cur and txt:
                spans.append((cur, txt)); txt = ""
            cur = key; txt += ch.data
        if txt: spans.append((cur, txt))
        out = "".join(f'<tspan fill="{c}"{" font-weight=\"bold\"" if b else ""}>{html.escape(t)}</tspan>' for (c, b), t in spans)
        rows.append(f'<text x="{PAD}" y="{PAD + (y + 1) * CH - 5}" xml:space="preserve" textLength="{COLS*CW}" lengthAdjust="spacingAndGlyphs">{out}</text>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="100%" height="100%" fill="{BG}"/>'
            f'<g font-family="Menlo" font-size="15">{"".join(rows)}</g></svg>')

i, n = 0, 0
frames = int((end + 0.5) * FPS)
last = None
for f in range(frames):
    t = f / FPS
    while i < len(chunks) and chunks[i][0] <= t:
        stream.feed(chunks[i][1]); i += 1
    s = svg_frame()
    path = f"{wd}/f{f:05d}.png"
    if s == last:
        os.link(f"{wd}/f{f-1:05d}.png", path)
    else:
        open(f"{wd}/frame.svg", "w").write(s)
        subprocess.run(["rsvg-convert", f"{wd}/frame.svg", "-o", path], check=True)
    last = s

# 3. gif
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS), "-i", f"{wd}/f%05d.png",
    "-vf", "split[a][b];[a]palettegen=max_colors=48:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle",
    "-loop", "0", out], check=True)
print(frames, "frames", os.path.getsize(out) // 1024, "KB")
