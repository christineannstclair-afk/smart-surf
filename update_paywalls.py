import re

# 1. Update surfer_pro_screen.dart
file_path_surfer = r'c:\Users\StCla\surf_passport - Copy\lib\features\surfer_pro\surfer_pro_screen.dart'
with open(file_path_surfer, 'r', encoding='utf-8') as f:
    surfer = f.read()

# Screen Title
surfer = surfer.replace(
    'title: Text(\n                "Surfer Pro",',
    'title: Text(\n                "Upgrade to Surfer Pro",'
)

# Section Headers & Supporting text
old_included = """        _FeatureList(
          title: t("Included Now", "Incluido Ahora"),
          items: [
            t("Structured Session Reflections", "Reflexiones de Sesión Estructuradas"),
            t("AI Performance Summaries", "Resúmenes de Rendimiento con IA"),
            t("Trend & Consistency Insights", "Información sobre Tendencias y Consistencia"),
            t("Shareable Session Cards", "Tarjetas de Sesión para Compartir"),
          ],
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        ),"""

new_included = """        _FeatureList(
          title: t("Why Go Pro?", "¿Por qué ser Pro?"),
          items: [
            t("Unlimited Session Logging", "Registro de Sesiones Ilimitado"),
            t("Advanced AI Analysis", "Análisis de IA Avanzado"),
            t("Deep Wave Biometrics", "Biometría de Olas Profunda"),
            t("Priority Support", "Soporte Prioritario"),
          ],
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        ),"""
surfer = surfer.replace(old_included, new_included)

old_coming = """        _FeatureList(
          title: t("Coming Soon", "Próximamente"),
          items: [
            t("AI Video Analysis (Pop-up & Turns)", "Análisis de Video con IA (Pop-up y Giros)"),
            t("Premium Skill Mapping", "Mapeo de Habilidades Premium"),
            t("Community Leaderboards", "Tablas de Clasificación de la Comunidad"),
          ],
          icon: Icons.access_time,
          iconColor: Colors.amber,
        ),"""

new_coming = """        _FeatureList(
          title: t("Features", "Características"),
          items: [
            t("Basic / Pro comparison active", "Comparativa Básico / Pro activa"),
          ],
          icon: Icons.star_border,
          iconColor: Colors.amber,
        ),"""
surfer = surfer.replace(old_coming, new_coming)


old_button = """        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              t("Get Surfer Pro", "Obtener Surfer Pro"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ),"""

new_button = """        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              t("Unlock Surfer Pro", "Desbloquear Surfer Pro"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: () {}, child: Text(t("Start Free Trial", "Iniciar Prueba Gratis"))),
            TextButton(onPressed: () {}, child: Text(t("Compare Plans", "Comparar Planes"))),
          ],
        ),"""
surfer = surfer.replace(old_button, new_button)

with open(file_path_surfer, 'w', encoding='utf-8') as f:
    f.write(surfer)


# 2. Update coach_pro_screen.dart
file_path_coach = r'c:\Users\StCla\surf_passport - Copy\lib\features\Settings\coach_pro_screen.dart'
with open(file_path_coach, 'r', encoding='utf-8') as f:
    coach = f.read()

# Title
coach = coach.replace(
    "'Coach Pro',",
    "'Upgrade to Coach Pro',",
    1
)

# Section Headers & Supporting Text
old_included_coach = """              _CategoryHeader(title: t("Included Now", "Incluido Ahora")),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.edit_document,
                title: t('Leave Private Notes', 'Deja Notas Privadas'),
                desc: t('Provide structured, session-specific feedback to help your athletes improve faster.', 'Proporciona comentarios estructurados por sesión para ayudar a tus atletas a mejorar más rápido.'),
              ),
              const SizedBox(height: 20),
              _BenefitRow(
                icon: Icons.analytics_outlined,
                title: t('Multi-Session Trends', 'Tendencias de Sesiones'),
                desc: t('Spot patterns in performance and see exactly where an athlete is excelling or struggling.', 'Detecta patrones de rendimiento y mira exactamente dónde destaca o tiene dificultades un atleta.'),
              ),
              const SizedBox(height: 32),

              _CategoryHeader(title: t("Coming Soon", "Próximamente")),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.group_outlined,
                title: t('Group Management', 'Gestión de Grupos'),
                desc: t('Organize students and track collective progress.', 'Organiza a los estudiantes y sigue el progreso colectivo.'),
              ),
              const SizedBox(height: 20),
              _BenefitRow(
                icon: Icons.calendar_month_outlined,
                title: t('Session Scheduling', 'Programación de Sesiones'),
                desc: t('Schedule and manage training blocks efficiently.', 'Programa y gestiona bloques de entrenamiento de manera eficiente.'),
              ),
              const SizedBox(height: 20),
              _BenefitRow(
                icon: Icons.description_outlined,
                title: t('Performance Reports', 'Informes de Rendimiento'),
                desc: t('Generate detailed reports for your students and sponsors.', 'Genera informes detallados para tus estudiantes y patrocinadores.'),
              ),"""

new_included_coach = """              _CategoryHeader(title: t("Coaching Tools", "Herramientas de Coach")),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.group_add_outlined,
                title: t('Unlimited Athlete Profiles', 'Perfiles de Atletas Ilimitados'),
                desc: t('Track as many surfers as you need.', 'Añade tantos surfistas como necesites.'),
              ),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.edit_note,
                title: t('Private Insight Logging', 'Registro de Insights Privados'),
                desc: t('Keep detailed notes on progression and technique.', 'Mantiene notas detalladas sobre la progresión y la técnica.'),
              ),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.video_library_outlined,
                title: t('Session Video Review', 'Revisión de Video de Sesión'),
                desc: t('Analyze footage and capture key moments.', 'Analiza videos y captura momentos clave.'),
              ),
              const SizedBox(height: 32),

              _CategoryHeader(title: t("Roster Management", "Gestión de Lista")),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: Icons.accessibility_new,
                title: t('Kinematic Feedback Models', 'Modelos de Feedback Cinemático'),
                desc: t('Advanced movement analysis tools.', 'Herramientas avanzadas de análisis de movimiento.'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(t("Free / Coach Pro", "Gratis / Coach Pro"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              ),"""
coach = coach.replace(old_included_coach, new_included_coach)

# Buttons
old_button_coach = """                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _purchase,
                        child: Text(
                          t('Upgrade to Coach Pro', 'Mejora a Coach Pro'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _restore,
                      child: Text(t('Restore Purchases', 'Restaurar Compras')),
                    ),"""

new_button_coach = """                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _purchase,
                        child: Text(
                          t('Unlock Coach Pro', 'Desbloquear Coach Pro'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(t('View Demo Roster', 'Ver Lista de Demostración')),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(t('Choose Plan', 'Elegir Plan')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _restore,
                      child: Text(t('Restore Purchases', 'Restaurar Compras')),
                    ),"""
coach = coach.replace(old_button_coach, new_button_coach)

with open(file_path_coach, 'w', encoding='utf-8') as f:
    f.write(coach)

print("Updated Paywalls UI copy")
