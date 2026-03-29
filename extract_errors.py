content = open('build_debug_full.txt', 'r', encoding='utf-8').read()
lines = content.splitlines()
for i, line in enumerate(lines):
    if 'lib/features/home/home_screen.dart:422:28:' in line:
        print('\n'.join(lines[i:i+30]))
