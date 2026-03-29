def find_deps():
    try:
        with open('pubspec.lock', 'r') as f:
            lines = f.readlines()
            current_pkg = ""
            for line in lines:
                # Top level packages in the lock file usually start with 2 spaces
                if line.startswith('  ') and not line.startswith('    '):
                    current_pkg = line.strip().replace(':', '')
                # Transitive dependencies are often listed later in 'pubspec.lock' 
                # but NOT as a child of the package that uses them (sadly).
                # Actually, pubspec.lock does NOT show which package depends on what.
                # It only shows 'direct main', 'direct dev', or 'transitive'.
                
                # Wait, I can look for 'dependency: "direct main"' or similar.
                pass
            
            # Let's just output the packages that are 'direct' vs 'transitive'
            image_version = ""
            for i, line in enumerate(lines):
                if '  image:' in line:
                    for j in range(i+1, min(i+10, len(lines))):
                        if 'version:' in lines[j]:
                            image_version = lines[j].strip().split(': ')[1]
                            break
            print(f"Current image version in lock: {image_version}")

            # Since the lock file doesn't help with reverse lookup,
            # I'll use 'flutter pub deps' output instead if it was captured.
            # But the 'flutter pub get' verbosity is better.
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_deps()
