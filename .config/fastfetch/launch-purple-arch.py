#!/usr/bin/env python3
import subprocess, re, os, shlex

LOGO = """[38;2;200;120;240m                   -`[0m
[38;2;200;120;240m                  .o+`[0m
[38;2;200;120;240m                 `ooo/[0m
[38;2;200;120;240m                `+oooo:[0m
[38;2;200;120;240m               `+oooooo:[0m
[38;2;200;120;240m               -+oooooo+:[0m
[38;2;200;120;240m             `/:-:++oooo+:[0m
[38;2;200;120;240m            `/++++/+++++++:[0m
[38;2;200;120;240m           `/++++++++++++++:[0m
[38;2;200;120;240m          `/+++ooooooooooooo/`[0m
[38;2;200;120;240m         ./ooosssso++osssssso+`[0m
[38;2;200;120;240m        .oossssso-````/ossssss+`[0m
[38;2;200;120;240m       -osssssso.      :ssssssso.[0m
[38;2;200;120;240m      :osssssss/        osssso+++.[0m
[38;2;200;120;240m     /ossssssss/        +ssssooo/-[0m
[38;2;200;120;240m   `/ossssso+/:-        -:/+osssso+-[0m
[38;2;200;120;240m  `+sso+:-`                 `.-/+oso:[0m
[38;2;200;120;240m `++:.                           `-/+/[0m
[38;2;200;120;240m .`                                 `/[0m"""

def strip_ansi(s):
    return re.sub(r'\[[0-9;]*m', '', s)

def visible_width(s):
    return len(strip_ansi(s))

# Run fastfetch in a pseudo-tty so it emits colors
cmd = 'fastfetch --config ' + shlex.quote(os.path.expanduser('~/.config/fastfetch/config-purple-arch.jsonc')) + ' --logo none'
result = subprocess.run(['script', '-q', '-c', cmd, '/dev/null'], capture_output=True, text=True)
stats = result.stdout.splitlines()
# Replace any magenta / bright magenta with truecolor purple
stats = [re.sub(r'\[35m', '[38;2;200;120;240m', line) for line in stats]
stats = [re.sub(r'\[95m', '[38;2;230;180;255m', line) for line in stats]

logo = LOGO.splitlines()
max_logo_width = max(visible_width(line) for line in logo) if logo else 0
sep = '   '
for i in range(max(len(logo), len(stats))):
    l = logo[i] if i < len(logo) else ''
    s = stats[i] if i < len(stats) else ''
    pad = max_logo_width - visible_width(l)
    print(l + ' ' * pad + sep + s)
