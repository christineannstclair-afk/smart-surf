import sys

def try_read(filename):
    for enc in ['utf-8', 'utf-16', 'utf-16le', 'latin-1']:
        try:
            with open(filename, 'r', encoding=enc) as f:
                content = f.read()
                if len(content) > 100:
                    return content
        except:
            continue
    return None

content = try_read('build_verbose.txt')
if content:
    lines = content.splitlines()
    found = False
    for i, line in enumerate(lines):
        if 'Error:' in line or 'lib/' in line or 'Target dart2js failed' in line:
            print(f"Match at line {i}: {line.strip()}")
            for j in range(1, 10):
                if i+j < len(lines):
                    print(f"  +{j}: {lines[i+j].strip()}")
            found = True
            # Break after first major error to avoid flooding
            if 'Error:' in line:
                break
    if not found:
        print("No matches found in build_verbose.txt")
else:
    print("Could not read build_verbose.txt with any common encoding")
