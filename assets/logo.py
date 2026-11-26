#!/usr/bin/env python3
"""Draw assets/logo.svg: ANSI-Shadow block letters made of rects, so it looks the same without the font. usage: python3 assets/logo.py assets/logo.svg"""
import sys

L = {
'D': ["██████╗ ","██╔══██╗","██║  ██║","██║  ██║","██████╔╝","╚═════╝ "],
'E': ["███████╗","██╔════╝","█████╗  ","██╔══╝  ","███████╗","╚══════╝"],
'V': ["██╗   ██╗","██║   ██║","██║   ██║","╚██╗ ██╔╝"," ╚████╔╝ ","  ╚═══╝  "],
'-': ["      ","      ","█████╗","╚════╝","      ","      "],
'T': ["████████╗","╚══██╔══╝","   ██║   ","   ██║   ","   ██║   ","   ╚═╝   "],
'A': [" █████╗ ","██╔══██╗","███████║","██╔══██║","██║  ██║","╚═╝  ╚═╝"],
'M': ["███╗   ███╗","████╗ ████║","██╔████╔██║","██║╚██╔╝██║","██║ ╚═╝ ██║","╚═╝     ╚═╝"],
}
word = "DEV-TEAM"
rows = ["".join(L[c][r] for c in word) for r in range(6)]

CW, CH, T = 11, 20, 3            # cell width, height, stroke
OX, OY = 60, 112                 # where the letters start
W = OX * 2 + len(rows[0]) * CW
H = 330

fill, shade = [], []
for y, row in enumerate(rows):
    for x, ch in enumerate(row):
        px, py = OX + x * CW, OY + y * CH
        cx, cy = px + CW // 2 - T // 2, py + CH // 2 - T // 2
        if ch == '█':
            fill.append(f'<rect x="{px}" y="{py}" width="{CW}" height="{CH}"/>')
            continue
        h_left = f'<rect x="{px}" y="{cy}" width="{CW//2+T//2+1}" height="{T}"/>'
        h_right = f'<rect x="{cx}" y="{cy}" width="{CW-CW//2+T//2}" height="{T}"/>'
        v_top = f'<rect x="{cx}" y="{py}" width="{T}" height="{CH//2+T//2+1}"/>'
        v_bot = f'<rect x="{cx}" y="{cy}" width="{T}" height="{CH-CH//2+T//2}"/>'
        parts = {
            '═': [f'<rect x="{px}" y="{cy}" width="{CW}" height="{T}"/>'],
            '║': [f'<rect x="{cx}" y="{py}" width="{T}" height="{CH}"/>'],
            '╗': [h_left, v_bot], '╔': [h_right, v_bot],
            '╝': [h_left, v_top], '╚': [h_right, v_top],
        }.get(ch, [])
        shade += parts

mono = "ui-monospace, 'SF Mono', Menlo, Consolas, 'DejaVu Sans Mono', monospace"
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="dev-team">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#b6ff3b"/>
      <stop offset="0.45" stop-color="#39ff14"/>
      <stop offset="1" stop-color="#00e676"/>
    </linearGradient>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#07130a"/>
      <stop offset="1" stop-color="#020703"/>
    </linearGradient>
    <filter id="glow" x="-10%" y="-30%" width="120%" height="160%">
      <feGaussianBlur stdDeviation="4" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <pattern id="scan" width="4" height="4" patternUnits="userSpaceOnUse">
      <rect width="4" height="1" fill="#000" opacity="0.35"/>
    </pattern>
    <pattern id="grid" width="22" height="22" patternUnits="userSpaceOnUse">
      <path d="M22 0H0V22" fill="none" stroke="#0f3d1a" stroke-width="1" opacity="0.6"/>
    </pattern>
  </defs>
  <rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="url(#bg)" stroke="#1f6b32" stroke-width="2"/>
  <rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="url(#grid)"/>
  <rect x="1" y="1" width="{W-2}" height="38" rx="14" fill="#0b1f10"/>
  <rect x="1" y="26" width="{W-2}" height="13" fill="#0b1f10"/>
  <line x1="1" y1="39" x2="{W-1}" y2="39" stroke="#1f6b32" stroke-width="1.5"/>
  <circle cx="26" cy="20" r="6" fill="#39ff14"/><circle cx="46" cy="20" r="6" fill="#1fbf4a"/><circle cx="66" cy="20" r="6" fill="#126b2b"/>
  <text x="{W/2}" y="25" text-anchor="middle" font-family="{mono}" font-size="14" fill="#5fbf6f">dev-team — 8 panes — zsh</text>
  <text x="{OX}" y="84" font-family="{mono}" font-size="20" fill="#39ff14"><tspan fill="#1fbf4a">~/code/my-app</tspan> <tspan fill="#b6ff3b">❯</tspan> /dev-team</text>
  <g fill="#14903a" opacity="0.95">{''.join(shade)}</g>
  <g fill="url(#g)" filter="url(#glow)">{''.join(fill)}</g>
  <text x="{OX}" y="{OY + 6*CH + 44}" font-family="{mono}" font-size="19" fill="#7dff8a">a software team in your terminal<tspan fill="#39ff14">
    <animate attributeName="opacity" values="1;1;0;0" keyTimes="0;0.5;0.5;1" dur="1.1s" repeatCount="indefinite"/>█</tspan></text>
  <text x="{OX}" y="{OY + 6*CH + 74}" font-family="{mono}" font-size="15" fill="#2e9c48">gateway · planner · 3 coders · issues · reviewer · comments</text>
  <rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="url(#scan)"/>
</svg>
'''
open(sys.argv[1], 'w').write(svg)
print(W, H)
