import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import '../../core/legal_utils.dart';
import '../coach_pro/subscription_service.dart';
import '../../core/subscription_config.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';

void showCoachProModal(BuildContext context, bool isSpanish) {
  showUpgradeBottomSheet(
    context: context,
    isSpanish: isSpanish,
    child: CoachProUpgradeContent(isSpanish: isSpanish),
  );
}

class CoachProUpgradeContent extends StatefulWidget {
  final bool isSpanish;

  const CoachProUpgradeContent({super.key, required this.isSpanish});

  @override
  State<CoachProUpgradeContent> createState() => _CoachProUpgradeContentState();
}

class _CoachProUpgradeContentState extends State<CoachProUpgradeContent> {
  final _subService = SubscriptionService();
  bool _isActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final active = await _subService.isCoachProActive();
    if (mounted) {
      setState(() {
        _isActive = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    try {
      final success = await _subService.purchaseCoachPro();
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _checkStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isSpanish ? '¡Compra exitosa!' : 'Purchase successful!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade800,
            ),
          );
        } else {
          // Silent cancellation - no SnackBar
          debugPrint('[CoachProUpgrade] Purchase cancelled or package not found. Finishing silently.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    final success = await _subService.restorePurchases();
    if (mounted) {
      _checkStatus();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSpanish ? 'Compras restauradas.' : 'Purchases restored.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSpanish ? 'No se encontraron compras activas.' : 'No active purchases found.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _manage() async {
    await _subService.openManageSubscriptions();
    _checkStatus();
  }

  String t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, size: 48, color: Colors.amber),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.web_asset, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    t("WEB PREVIEW ONLY", "VISTA PREVIA WEB"),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t('Upgrade to Coach Pro', 'Mejorar a Coach Pro'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.2),
          ),
          const SizedBox(height: 12),
          if (_isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                t('Pro Status: Active', 'Estado Pro: Activo'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            )
          else
          Text(
            t(
              'The essential toolkit for surf coaches. Manage your athletes, track multi-session trends, and provide structured feedback.',
              'El kit de herramientas esencial para entrenadores de surf. Gestiona a tus atletas, sigue tendencias y proporciona feedback estructurado.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            t(
              'Start your subscription today. Cancel anytime directly from your settings.',
              'Inicia tu suscripción hoy. Cancela en cualquier momento desde tu configuración.',
            ),
            textAlign: TextAlign.center,
             style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 16),
          
          _CategoryHeader(title: t("Technical Tools", "Herramientas Técnicas")),
          const SizedBox(height: 12),
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
          ),
          const SizedBox(height: 32),
          
          _PricingDisplay(isSpanish: widget.isSpanish),
          
          const SizedBox(height: 24),

          SafeArea(
            bottom: true,
            top: false,
            child: _isLoading
              ? const CircularProgressIndicator()
              : _isActive
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _manage,
                          child: Text(
                            t('Manage Subscription', 'Gestionar Suscripción'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('Close', 'Cerrar')),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _purchase,
                          child: Text(
                            t('Unlock Coach Pro', 'Desbloquear Coach Pro'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      t(
                        'Coach Pro purchases available on iOS/Android.',
                        'Las compras de Coach Pro están disponibles en iOS/Android.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ), // SafeArea close
          const SizedBox(height: 24),
          LegalUtils.buildLegalFooter(
            context: context, 
            isSpanish: widget.isSpanish,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _BenefitRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingDisplay extends StatelessWidget {
  final bool isSpanish;
  const _PricingDisplay({required this.isSpanish});

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            t("SPECIAL FOUNDING PRICE", "PRECIO ESPECIAL DE FUNDADOR"),
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Use wrap on very small screens, row on normal ones
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 320 ? constraints.maxWidth : (constraints.maxWidth / 2) - 6,
                  child: _PricingCard(
                    title: t("Monthly", "Mensual"),
                    price: SubscriptionConfig.coachMonthlyStr,
                    period: t("/month", "/mes"),
                    isSpanish: isSpanish,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 320 ? constraints.maxWidth : (constraints.maxWidth / 2) - 6,
                  child: _PricingCard(
                    title: t("Annual", "Anual"),
                    price: SubscriptionConfig.coachAnnualStr,
                    period: t("/year", "/año"),
                    isSpanish: isSpanish,
                    isDiscounted: true,
                  ),
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isSpanish;
  final bool isDiscounted;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isSpanish,
    this.isDiscounted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDiscounted ? Colors.amber : colorScheme.outlineVariant,
          width: isDiscounted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isDiscounted)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                isSpanish ? "DESCUENTO" : "DISCOUNTED",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isDiscounted ? Colors.amber : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              Text(
                period,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }
}
