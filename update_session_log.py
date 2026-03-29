import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\session_log\session_log_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Let's replace the whole bottom sheet column contents carefully.
# We will use regex to find the `return Column(` inside `_openAddSessionSheet`
# But it's easier to replace specific chunks.

# 1. Title and Session Details header
old_title_area = """                        Text(
                          t("Log a session", "Registrar sesión"),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickDate,
                                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                                label: Text(t("Date: ", "Fecha: ") + dateLabel()),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),"""

new_title_area = """                        Text(
                          t("Log Session", "Registrar Sesión"),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t("Session Details", "Detalles de la sesión"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickDate,
                                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                                label: Text(t("Date: ", "Fecha: ") + dateLabel()),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),"""
content = content.replace(old_title_area, new_title_area)


# 2. Re-map the location fields to have "Location" label
old_location_area = """                        const SizedBox(height: 16),
                        TextField(
                          controller: spotCtrl,
                          decoration: InputDecoration(
                            labelText: t("Spot name", "Nombre del spot"),
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regionCtrl,
                          decoration: InputDecoration(
                            labelText: t("Region / Country", "Región / País"),
                            prefixIcon: const Icon(Icons.public_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),"""

new_location_area = """                        const SizedBox(height: 16),
                        TextField(
                          controller: spotCtrl,
                          decoration: InputDecoration(
                            labelText: t("Location", "Ubicación"),
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regionCtrl,
                          decoration: InputDecoration(
                            labelText: t("Region / Country", "Región / País"),
                            prefixIcon: const Icon(Icons.public_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),"""
content = content.replace(old_location_area, new_location_area)

# 3. Wave Height & Conditions & Focus & Board dropdowns
old_dropdown_area = """                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: waveSize,
                          decoration: InputDecoration(
                            labelText: t("Wave size", "Tamaño de ola"),
                            prefixIcon: const Icon(Icons.waves_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: PassportPresets.waveSizes.map((m) {
                            return DropdownMenuItem(
                              value: m["en"]!,
                              child: Text(PassportPresets.formatWaveSize(m["en"]!, widget.units)),
                            );
                          }).toList(),
                          onChanged: (v) => setSheetState(() => waveSize = v ?? "1-2ft"),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: sessionFocus,
                          decoration: InputDecoration(
                            labelText: t("Session focus", "Enfoque"),
                            prefixIcon: const Icon(Icons.center_focus_strong_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "General", child: Text(t("General", "General"))),
                            DropdownMenuItem(value: "Paddling", child: Text(t("Paddling", "Remada"))),
                            DropdownMenuItem(value: "Pop up", child: Text(t("Pop up", "Pararse"))),
                            DropdownMenuItem(value: "Takeoff", child: Text(t("Takeoff", "Despegue"))),
                            DropdownMenuItem(value: "Trimming", child: Text(t("Trimming", "Recorrer la ola"))),
                            DropdownMenuItem(value: "Turns", child: Text(t("Turns", "Giros"))),
                            DropdownMenuItem(value: "Confidence", child: Text(t("Confidence", "Confianza"))),
                          ],
                          onChanged: (v) => setSheetState(() => sessionFocus = v ?? "General"),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: board,
                          decoration: InputDecoration(
                            labelText: t("Board", "Tabla"),
                            prefixIcon: const Icon(Icons.surfing_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "Soft top", child: Text(t("Soft top", "Soft top"))),
                            DropdownMenuItem(value: "Mini mal", child: Text(t("Mini mal", "Mini mal"))),
                            DropdownMenuItem(value: "Longboard", child: Text(t("Longboard", "Longboard"))),
                            DropdownMenuItem(value: "Funboard", child: Text(t("Funboard", "Funboard"))),
                            DropdownMenuItem(value: "Shortboard", child: Text(t("Shortboard", "Shortboard"))),
                          ],
                          onChanged: (v) => setSheetState(() => board = v ?? "Soft top"),
                        ),"""

new_dropdown_area = """                        const SizedBox(height: 24),
                        Text(
                          t("Wave Height", "Tamaño de ola"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: "2-3ft", // Defaulting based on spec
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.waves_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "2-3ft", child: Text("2-3ft")),
                            DropdownMenuItem(value: "3-4ft", child: Text("3-4ft")),
                            DropdownMenuItem(value: "4-6ft", child: Text("4-6ft")),
                          ],
                          onChanged: (v) => setSheetState(() => waveSize = v ?? "2-3ft"),
                        ),
                        
                        const SizedBox(height: 16),
                        Text(
                          t("Conditions", "Condiciones"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: "Clean",
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.water_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "Glassy", child: Text(t("Glassy", "Glassy"))),
                            DropdownMenuItem(value: "Clean", child: Text(t("Clean", "Limpio"))),
                            DropdownMenuItem(value: "Choppy", child: Text(t("Choppy", "Picado"))),
                          ],
                          onChanged: (v) => setSheetState(() => conditionsCtrl.text = v ?? "Clean"),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          t("Board", "Tabla"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          hint: Text(t("Select board from quiver...", "Seleccionar tabla del quiver...")),
                          value: null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.surfing_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "Soft top", child: Text(t("Soft top", "Soft top"))),
                            DropdownMenuItem(value: "Shortboard", child: Text(t("Shortboard", "Shortboard"))),
                            DropdownMenuItem(value: "Longboard", child: Text(t("Longboard", "Longboard"))),
                          ],
                          onChanged: (v) => setSheetState(() => board = v ?? "Soft top"),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          t("Focus Skills", "Habilidades foco"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: "Bottom Turn",
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.center_focus_strong_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "Bottom Turn", child: Text(t("Bottom Turn", "Bottom Turn"))),
                            DropdownMenuItem(value: "Cutback", child: Text(t("Cutback", "Cutback"))),
                            DropdownMenuItem(value: "Duck Dive", child: Text(t("Duck Dive", "Pato"))),
                            DropdownMenuItem(value: "Snap", child: Text(t("Snap", "Snap"))),
                            DropdownMenuItem(value: "Tube Ride", child: Text(t("Tube Ride", "Tubo"))),
                          ],
                          onChanged: (v) => setSheetState(() => sessionFocus = v ?? "Bottom Turn"),
                        ),"""
content = content.replace(old_dropdown_area, new_dropdown_area)


# 4. Notes & Media & Save button
old_notes = """                        ] else ...[
                          TextField(
                            controller: notesCtrl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: t("Notes", "Notas"),
                              hintText: t("What felt good? Challenges? Conditions?", "¿Qué salió bien? ¿Retos? ¿Condiciones?"),
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(t("Save session", "Guardar sesión")),"""

new_notes = """                        ] else ...[
                          const SizedBox(height: 16),
                          Text(
                            t("Notes", "Notas"),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: t("How was the session?", "¿Cómo estuvo la sesión?"),
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],

                        // Media Section
                        const SizedBox(height: 24),
                        Text(
                          t("Media", "Medios"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(t("Add Media", "Agregar Medio")),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(t("Log Session", "Registrar Sesión")),"""
content = content.replace(old_notes, new_notes)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated session_log_screen.dart copy")
