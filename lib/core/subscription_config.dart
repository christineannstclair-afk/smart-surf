class SubscriptionConfig {
  // Entitlement IDs (RevenueCat)
  static const String entitlementCoachPro = 'coach_pro';
  static const String entitlementSurferPro = 'surfer_pro';

  // Offering ID
  static const String offeringDefault = 'default';

  // SKU / Package IDs
  static const String skuCoachMonthly = 'cp_monthly';
  static const String skuCoachAnnual = 'cp_annual';
  static const String skuSurferMonthly = 'sp_monthly';
  static const String skuSurferAnnual = 'sp_annual';

  // Fallback Pricing (Used for Web/Mock)
  static const double priceCoachMonthly = 9.99;
  static const double priceCoachAnnual = 79.99;
  static const double priceSurferMonthly = 2.99;
  static const double priceSurferAnnual = 19.99;

  static String get coachMonthlyStr => "\$${priceCoachMonthly.toStringAsFixed(2)}";
  static String get coachAnnualStr => "\$${priceCoachAnnual.toStringAsFixed(2)}";
  static String get surferMonthlyStr => "\$${priceSurferMonthly.toStringAsFixed(2)}";
  static String get surferAnnualStr => "\$${priceSurferAnnual.toStringAsFixed(2)}";
}
