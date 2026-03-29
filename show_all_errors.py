import sys

def run():
    try:
        with open('full_analysis.txt', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
            for line in lines:
                if 'error -' in line:
                    print(line.strip())
    except Exception as e:
        print(f"Error reading file: {e}")

if __name__ == "__main__":
    run()
