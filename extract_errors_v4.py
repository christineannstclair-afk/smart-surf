with open('build_debug_full.txt', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if 'lib/' in line or 'Error:' in line:
            print(f"Line {i}: {line.strip()}")
            for j in range(1, 10):
                if i + j < len(lines):
                    print(f"  +{j}: {lines[i+j].strip()}")
            # Break after first error to avoid too much output
            break
