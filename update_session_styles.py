import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\session_log\session_log_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the Main Scaffold background and list padding
content = content.replace(
    """      body: ListView(
        padding: const EdgeInsets.all(14),""",
    """      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),"""
)

# 2. Update the session log cards to match the standard Tap Cards
old_session_card = """              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.surfing, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 24),
                    ),
                    title: Text(
                      "${e.spotName} (${e.durationMins}m)",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(dateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(subtitleParts.join(" · "), style: const TextStyle(fontSize: 12)),
                        if (e.aiSummary != null && widget.isSurferPro) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                  Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.aiSummary!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if ((e.notes.isNotEmpty || e.reflectionWhatFeltGood != null) && !widget.isSurferPro) ...[
                           const SizedBox(height: 8),
                           Text(e.notes, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                        if (widget.isSurferPro && (e.reflectionWhatFeltGood?.isNotEmpty == true || e.reflectionWhatWasChallenging?.isNotEmpty == true)) ...[
                          const SizedBox(height: 12),
                          if (e.reflectionWhatFeltGood?.isNotEmpty == true)
                            _ReflectionShortcut(label: t("Felt Good", "Bien"), content: e.reflectionWhatFeltGood!),
                          if (e.reflectionWhatWasChallenging?.isNotEmpty == true)
                            _ReflectionShortcut(label: t("Challenge", "Reto"), content: e.reflectionWhatWasChallenging!),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => widget.onDelete(e.id),
                    ),
                  ),
                ),
              );"""

new_session_card = """              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.surfing, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${e.spotName} (${e.durationMins}m)",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleParts.join(" · "),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                            if (e.aiSummary != null && widget.isSurferPro) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.aiSummary!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if ((e.notes.isNotEmpty || e.reflectionWhatFeltGood != null) && !widget.isSurferPro) ...[
                               const SizedBox(height: 8),
                               Text(e.notes, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                            ],
                            if (widget.isSurferPro && (e.reflectionWhatFeltGood?.isNotEmpty == true || e.reflectionWhatWasChallenging?.isNotEmpty == true)) ...[
                              const SizedBox(height: 12),
                              if (e.reflectionWhatFeltGood?.isNotEmpty == true)
                                _ReflectionShortcut(label: t("Felt Good", "Bien"), content: e.reflectionWhatFeltGood!),
                              if (e.reflectionWhatWasChallenging?.isNotEmpty == true)
                                _ReflectionShortcut(label: t("Challenge", "Reto"), content: e.reflectionWhatWasChallenging!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => widget.onDelete(e.id),
                      ),
                    ],
                  ),
                ),
              );"""

content = content.replace(old_session_card, new_session_card)

# 3. Update the AI Video Analysis Card
old_ai_card = """    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1),
      ),
      elevation: 0,
      color: Colors.amber.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t("AI Video Analysis", "Análisis de Video IA"), style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(dateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(t("Focus", "Enfoque") + ": ${a.focusArea}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t("Solid", "Sólido") + ": ${a.looksSolid}", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(t("Improvement", "Mejora") + ": ${a.primaryImprovement}", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(t("Drill", "Ejercicio") + ": ${a.drillToPractice}", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );"""

new_ai_card = """    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.amber.withOpacity(0.5)),
      ),
      color: Colors.amber.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  t("AI Video Analysis", "Análisis de Video IA"),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.amber.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(t("Focus", "Enfoque") + ": ${a.focusArea}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t("Solid", "Sólido") + ": ${a.looksSolid}", style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 8),
            Text(t("Improvement", "Mejora") + ": ${a.primaryImprovement}", style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 8),
            Text(t("Drill", "Ejercicio") + ": ${a.drillToPractice}", style: const TextStyle(fontSize: 13, height: 1.3)),
          ],
        ),
      ),
    );"""

content = content.replace(old_ai_card, new_ai_card)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated session_log_screen.dart styles")
