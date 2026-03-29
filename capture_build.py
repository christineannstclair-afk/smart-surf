import subprocess
import os

def run_build():
    cmd = ['flutter', 'build', 'web', '--no-wasm-dry-run']
    # Use Popen to capture everything
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=os.getcwd(), shell=True)
    stdout, stderr = process.communicate()
    
    # Write to a file using UTF-8 to avoid encoding issues
    with open('build_debug_full.txt', 'w', encoding='utf-8') as f:
        f.write("STDOUT:\n")
        f.write(stdout)
        f.write("\n\nSTDERR:\n")
        f.write(stderr)
    
    print("Build complete. See build_debug_full.txt")
    if process.returncode != 0:
        print(f"Build failed with exit code {process.returncode}")

if __name__ == "__main__":
    run_build()
