with open('build_debug_full.txt', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()
    if 'STDERR:' in content:
        stderr_part = content.split('STDERR:')[1]
        print("--- STDERR ---")
        print(stderr_part)
    else:
        print("STDERR: tag not found")
