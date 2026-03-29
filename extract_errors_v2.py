content = open('build_debug_full.txt', 'r', encoding='utf-8', errors='ignore').read()
idx = content.find('lib/features/home/home_screen.dart:422:28:')
if idx != -1:
    print(content[idx:idx+1000])
else:
    print("Error string not found")
