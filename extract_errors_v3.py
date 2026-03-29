with open('build_debug_full.txt', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if 'Error:' in line or 'lib/' in line:
            print(f"Line {i}: {line.strip()}")
            # Print a few lines after if it looks like a multi-line error
            if 'Error:' in line:
                for j in range(1, 10):
                    if i + j < len(lines):
                        print(f"  +{j}: {lines[i+j].strip()}")
