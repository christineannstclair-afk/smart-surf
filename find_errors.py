import sys

with open('analyze_compact.txt', 'r', encoding='utf-16le', errors='ignore') as f:
    lines = f.readlines()
    for line in lines:
        if 'Error' in line:
            print(line.strip())
