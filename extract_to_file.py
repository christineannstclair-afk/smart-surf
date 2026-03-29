with open('full_analysis.txt', 'r', encoding='utf-16le', errors='ignore') as f:
    lines = f.readlines()

with open('errors_only.txt', 'w', encoding='utf-8') as f:
    for line in lines:
        if 'error -' in line:
            f.write(line.strip() + '\n')
