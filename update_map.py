import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\map\map_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Screen Title
content = content.replace("Text(_t('Map', 'Mapa'))", "Text(_t('Surf Map', 'Mapa de Surf'))")

# 2. Search placeholder
content = content.replace("'Search beaches, towns, regions...'", "'Search for beaches...'")
content = content.replace("'Buscar playas, pueblos, regiones...'", "'Buscar playas...'")

# 3. Section Header: Saved Spots
content = content.replace("_t('Surf Spots', 'Spots de Surf')", "_t('Saved Spots', 'Spots Guardados')")

# 4. "4 spots found active today" instead of "X total"
old_total_badge = """                child: Text(
                  '${spots.length} ${_t("total", "en total")}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),"""
new_total_badge = """                child: Text(
                  '${spots.length} ${_t("spots found active today", "spots activos encontrados hoy")}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),"""
content = content.replace(old_total_badge, new_total_badge)

# 5. Add "Button Labels" (Map, Forecast, Saved, Profile) as a Row of buttons under Search bar in wide layout
old_wide_search = """              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _t('Search for beaches...', 'Buscar playas...'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _handleSearch,
              ),
              if (_searchResults.isNotEmpty)
                _buildAutocompleteOverlay(),
            ],
          ),
        ),"""

new_wide_search = """              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _t('Search for beaches...', 'Buscar playas...'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _handleSearch,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(label: Text(_t("Map", "Mapa")), onPressed: () {}),
                  const SizedBox(width: 8),
                  ActionChip(label: Text(_t("Forecast", "Pronóstico")), onPressed: () {}),
                  const SizedBox(width: 8),
                  ActionChip(label: Text(_t("Saved", "Guardados")), onPressed: () {}),
                  const SizedBox(width: 8),
                  ActionChip(label: Text(_t("Profile", "Perfil")), onPressed: () {}),
                ],
              ),
              if (_searchResults.isNotEmpty)
                _buildAutocompleteOverlay(),
            ],
          ),
        ),"""
content = content.replace(old_wide_search, new_wide_search)

# 6. Add "Button Labels" (Map, Forecast, Saved, Profile) under search in mobile layout
old_mobile_search = """                    if (_searchResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildAutocompleteOverlay(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),"""

new_mobile_search = """                    if (_searchResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildAutocompleteOverlay(),
                      ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(label: Text(_t("Map", "Mapa")), onPressed: () {}),
                          const SizedBox(width: 8),
                          ActionChip(label: Text(_t("Forecast", "Pronóstico")), onPressed: () {}),
                          const SizedBox(width: 8),
                          ActionChip(label: Text(_t("Saved", "Guardados")), onPressed: () {}),
                          const SizedBox(width: 8),
                          ActionChip(label: Text(_t("Profile", "Perfil")), onPressed: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),"""
content = content.replace(old_mobile_search, new_mobile_search)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated map_screen.dart copy")
