import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/subscription_config.dart';

abstract class SubscriptionService {
  Future<void> init();
  
  // Coach Pro
  Future<bool> isCoachProActive();
  Future<bool> purchaseCoachPro();
  
  // Surfer Pro
  Future<bool> isSurferProActive();
  Future<bool> isSurferTrialActive();
  Future<bool> purchaseSurferPro();
  
  Future<bool> restorePurchases();
  Future<void> openManageSubscriptions();

  factory SubscriptionService() {
      return LocalSubscriptionService();
    }
}

class RevenueCatSubscriptionService implements SubscriptionService {
  @override
  Future<void> init() async {
    // Configure RevenueCat here later when API keys are available:
    // await Purchases.configure(PurchasesConfiguration("YOUR_API_KEY"));
  }

  @override
  Future<bool> isCoachProActive() async {
    return _isEntitlementActive(SubscriptionConfig.entitlementCoachPro);
  }

  @override
  Future<bool> isSurferProActive() async {
    return _isEntitlementActive(SubscriptionConfig.entitlementSurferPro);
  }

  @override
  Future<bool> isSurferTrialActive() async {
    // RevenueCat trial detection would go here. For now, return false.
    return false;
  }

  Future<bool> _isEntitlementActive(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> purchaseCoachPro() async {
    // For now, we return false as we are in preview mode without keys
    // In production, this would call _purchaseEntitlement(SubscriptionConfig.entitlementCoachPro);
    return false;
  }

  @override
  Future<bool> purchaseSurferPro() async {
    return false;
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final coachActive = customerInfo.entitlements.all[SubscriptionConfig.entitlementCoachPro]?.isActive ?? false;
      final surferActive = customerInfo.entitlements.all[SubscriptionConfig.entitlementSurferPro]?.isActive ?? false;
      return coachActive || surferActive;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openManageSubscriptions() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final url = customerInfo.managementURL;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open manage subscriptions: $e');
    }
  }
}

class LocalSubscriptionService implements SubscriptionService {
  static const String _coachKey = 'coach_pro_active';
  static const String _surferKey = 'surfer_pro_active';
  static const String _surferTrialKey = 'surfer_pro_trial';

  @override
  Future<void> init() async {}

  @override
  Future<bool> isCoachProActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_coachKey) ?? false;
  }

  @override
  Future<bool> isSurferProActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_surferKey) ?? false;
  }

  @override
  Future<bool> isSurferTrialActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_surferTrialKey) ?? false;
  }

  @override
  Future<bool> purchaseCoachPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coachKey, true);
    return true;
  }

  @override
  Future<bool> purchaseSurferPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_surferKey, true);
    await prefs.setBool(_surferTrialKey, true); // Assume trial on local purchase
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    final coach = await isCoachProActive();
    final surfer = await isSurferProActive();
    return coach || surfer;
  }

  @override
  Future<void> openManageSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coachKey, false);
    await prefs.setBool(_surferKey, false);
    await prefs.setBool(_surferTrialKey, false);
    debugPrint('Local subscriptions revoked for testing.');
  }
}
