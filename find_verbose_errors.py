with open('build_verbose.txt', 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        if 'Error:' in line or 'lib/' in line:
            print(line.strip())
