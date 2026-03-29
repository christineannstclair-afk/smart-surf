import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Locate the injected pattern
pattern = re.compile(r'  Widget _buildProfileSection\(BuildContext context\) \{.*?\@override\n  Widget build\(BuildContext context\) \{', re.DOTALL)

matches = list(pattern.finditer(content))

if len(matches) > 1:
    # Keep the first match, replace the others
    first_match_end = matches[0].end()
    rest_content = content[first_match_end:]
    
    # In the rest of the content, replace the pattern with just the @override build
    fixed_rest = pattern.sub('  @override\n  Widget build(BuildContext context) {', rest_content)
    
    final_content = content[:first_match_end] + fixed_rest
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(final_content)
    print(f"Fixed {len(matches)-1} redundant injections.")
else:
    print("No redundant injections found.")
