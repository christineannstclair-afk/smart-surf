import 'package:flutter/material.dart';
import '../../ui_system/app_theme.dart';
import '../../core/legal_utils.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';
import '../../core/subscription_config.dart';
import '../session_log/firebase_service.dart';
import '../coach_pro/subscription_service.dart';

void showSurfInsightPaywall(BuildContext context, {bool isSpanish = false}) {
  showUpgradeBottomSheet(
    context: context,
    isSpanish: isSpanish,
    child: SurfInsightPaywall(isSpanish: isSpanish),
  );
}

class SurfInsightPaywall extends StatefulWidget {
  final bool isSpanish;

  const SurfInsightPaywall({super.key, this.isSpanish = false});

  @override
  State<SurfInsightPaywall> createState() => _SurfInsightPaywallState();
}

class _SurfInsightPaywallState extends State<SurfInsightPaywall> {
  final _subService = SubscriptionService();
  bool _isLoading = false;

  String _t(String en, String es) => widget.isSpanish ? es : en;

  void _restorePurchases(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final success = await _subService.restorePurchases();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? _t('Purchases restored successfully!', '¡Compras restauradas con éxito!')
                : _t('No active purchases found to restore.', 'No se encontraron compras activas para restaurar.')
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success ? Colors.green.shade800 : Colors.blueGrey,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _selectedPackageId = 'monthly';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header showing brand / icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _t("Finally understand your surfing", "Finalmente entiende tu surf"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            _t("Want insights after every surf?", "¿Quieres insights después de cada surf?"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Feature List
          _buildFeatureRow(context, _t("AI Surf Insights from your sessions", "Insights de IA de tus sesiones")),
          const SizedBox(height: 12),
          _buildFeatureRow(context, _t("Progress patterns across recent surfs", "Patrones de progreso en sesiones recientes")),
          const SizedBox(height: 12),
          _buildFeatureRow(context, _t("Next session focus suggestions", "Sugerencias de enfoque para tu próxima sesión")),
          const SizedBox(height: 32),

          // PRICING SELECTION
          _buildSelectionTile(
            id: 'monthly',
            title: _t("Monthly", "Mensual"),
            price: SubscriptionConfig.surferMonthlyStr,
            subtitle: _t("Billed monthly", "Facturado mensualmente"),
          ),
          const SizedBox(height: 12),
          _buildSelectionTile(
            id: 'annual',
            title: _t("Annual", "Anual"),
            price: SubscriptionConfig.surferAnnualStr,
            subtitle: _t("Best Value! Billed yearly", "¡Mejor Valor! Facturado anualmente"),
            isBestValue: true,
          ),

          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                FirebaseService().logEvent('upgrade_clicked', parameters: {'package': _selectedPackageId});
                
                try {
                  final success = await _subService.purchaseSurferPro(packageId: _selectedPackageId);
                  
                  if (mounted) {
                     setState(() => _isLoading = false);
                     if (success) {
                       Navigator.pop(context);
                     } else {
                       debugPrint('[SurfInsightPaywall] User cancelled or no package found.');
                     }
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red.shade800,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _t("Start 3-Day Free Trial", "Comenzar prueba gratis de 3 días"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t("3-day free trial, then ${ _selectedPackageId == 'annual' ? SubscriptionConfig.surferAnnualStr : SubscriptionConfig.surferMonthlyStr}. Cancel anytime.\nYour subscription automatically renews unless canceled at least 24 hours before the end of the trial.", 
               "Prueba de 3 días, luego ${ _selectedPackageId == 'annual' ? SubscriptionConfig.surferAnnualStr : SubscriptionConfig.surferMonthlyStr}. Cancela cuando quieras.\nTu suscripción se renueva automáticamente a menos que se cancele 24 horas antes."),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Legal Footer
          LegalUtils.buildLegalFooter(
            context: context,
            isSpanish: widget.isSpanish,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _t("Cancel", "Cancelar"),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text("|", style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.3))),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isLoading ? null : () => _restorePurchases(context),
                child: Text(
                  _t("Restore Purchases", "Restaurar Compras"),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    bool isBestValue = false,
  }) {
    final isSelected = _selectedPackageId == id;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : colorScheme.outline.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? const Center(child: Icon(Icons.circle, size: 10, color: AppTheme.primary)) 
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("VALUE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: AppTheme.primary.withOpacity(0.8), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
