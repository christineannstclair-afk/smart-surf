import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/subscription_config.dart';

abstract class SubscriptionService {
  Future<void> init();
  
  // Coach Pro
  Future<bool> isCoachProActive();
  Future<bool> purchaseCoachPro({String packageId = 'monthly'});
  
  // Surfer Pro
  Future<bool> isSurferProActive();
  Future<bool> isSurferTrialActive();
  Future<bool> purchaseSurferPro({String packageId = 'monthly'});
  
  Future<bool> restorePurchases();
  Future<void> openManageSubscriptions();
  Future<void> logIn(String appUserID);
  Future<void> logOut();

  factory SubscriptionService() {
    if (kIsWeb) {
      return LocalSubscriptionService();
    }
    return RevenueCatSubscriptionService();
  }
}

class RevenueCatSubscriptionService implements SubscriptionService {
  @override
  Future<void> init() async {
    try {
      debugPrint('[PurchaseService] Initializing RevenueCat with ID: ${SubscriptionConfig.apiKey}');
      if (SubscriptionConfig.apiKey == 'goog_example_api_key_here') {
         debugPrint('[PurchaseService] WARNING: Using placeholder API key. Purchases will fail.');
      }
      await Purchases.configure(PurchasesConfiguration(SubscriptionConfig.apiKey));
      debugPrint('[PurchaseService] RevenueCat configured successfully.');
    } catch (e) {
      debugPrint('[PurchaseService] RevenueCat configuration FAILED: $e');
    }
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
      debugPrint('[PurchaseService] Checking entitlement status for: $entitlementId');
      debugPrint('[PurchaseService] Identifiers in customerInfo:');
      debugPrint('   - Entitlements: ${customerInfo.entitlements.all.keys.join(', ')}');
      debugPrint('   - Active Subscriptions: ${customerInfo.activeSubscriptions.join(', ')}');
      
      final active = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      debugPrint('[PurchaseService] Is "$entitlementId" active? $active');
      return active;
    } catch (e) {
      debugPrint('[PurchaseService] Error fetching entitlement status: $e');
      return false;
    }
  }

  @override
  Future<bool> purchaseCoachPro({String packageId = 'monthly'}) async {
    try {
      debugPrint('[PurchaseService] Starting Coach Pro purchase ($packageId)...');
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current ?? offerings.all[SubscriptionConfig.offeringDefault];
      
      final package = packageId == 'annual' ? offering?.annual : offering?.monthly;
      
      if (package == null) {
        debugPrint('[PurchaseService] No package found for Coach Pro with ID: $packageId');
        return false;
      }

      final result = await Purchases.purchasePackage(package);
      final active = result.customerInfo.entitlements.all[SubscriptionConfig.entitlementCoachPro]?.isActive ?? false;
      debugPrint('[PurchaseService] Coach Pro purchase result: active = $active');
      return active;
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] PlatformException during Coach Pro purchase: code=${e.code}, message=${e.message}');
      
      // Handle user cancellation silently
      if (e.code == '1') {
        final active = await _isEntitlementActive(SubscriptionConfig.entitlementCoachPro);
        if (active) {
            debugPrint('[PurchaseService] Suppressing cancellation because entitlement is ACTIVE.');
            return true;
        }
        debugPrint('[PurchaseService] Silent cancellation detected.');
        return false;
      }
      
      throw 'Store Error (${e.code}): ${e.message}';
    } catch (e) {
      debugPrint('[PurchaseService] Coach Pro purchase failed: $e');
      throw e.toString();
    }
  }

  @override
  Future<bool> purchaseSurferPro({String packageId = 'monthly'}) async {
    try {
      debugPrint('[PurchaseService] Starting Surfer Pro purchase flow ($packageId)...');
      
      final offerings = await Purchases.getOfferings();
      debugPrint('[PurchaseService] Offerings fetched: ${offerings.all.keys.join(', ')}');
      
      // Prioritize the Current Offering set in the RevenueCat dashboard
      var offering = offerings.current;
      
      // Fallback only if current is not set, specifically looking for our default ID
      if (offering == null) {
        debugPrint('[PurchaseService] offerings.current is null. Falling back to specific offering ID: ${SubscriptionConfig.offeringDefault}');
        offering = offerings.all[SubscriptionConfig.offeringDefault];
      }
      
      if (offering == null) {
         throw 'No offerings available in RevenueCat. Please set a "Current" offering in your dashboard or add an offering with ID: ${SubscriptionConfig.offeringDefault}';
      }

      debugPrint('[PurchaseService] Using Offering: ${offering.identifier}');
      debugPrint('[PurchaseService] Available Packages in this Offering: ${offering.availablePackages.map((p) => p.identifier).join(', ')}');
      
      final package = packageId == 'annual' ? offering.annual : offering.monthly;
      if (package == null) {
        throw 'No $packageId package found in RevenueCat offering: ${offering.identifier}';
      }

      debugPrint('[PurchaseService] Package identified: ${package.identifier} for product: ${package.storeProduct.identifier}');
      debugPrint('[PurchaseService] Calling Purchases.purchasePackage(package)...');
      
      final result = await Purchases.purchasePackage(package);
      final active = result.customerInfo.entitlements.all[SubscriptionConfig.entitlementSurferPro]?.isActive ?? false;
      
      debugPrint('[PurchaseService] Purchase transaction complete.');
      debugPrint('[PurchaseService] Post-purchase status:');
      debugPrint('   - Entitlements active: ${result.customerInfo.entitlements.active.keys.join(', ')}');
      debugPrint('   - Subscriptions active: ${result.customerInfo.activeSubscriptions.join(', ')}');
      debugPrint('[PurchaseService] Entitlement "${SubscriptionConfig.entitlementSurferPro}" active: $active');
      
      return active;
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] PlatformException during Surfer Pro purchase: code=${e.code}, message=${e.message}');
      
      // Handle user cancellation silently (code 1)
      if (e.code == '1') {
        final active = await _isEntitlementActive(SubscriptionConfig.entitlementSurferPro);
        if (active) {
           debugPrint('[PurchaseService] Suppressing cancellation because entitlement is ACTIVE.');
           return true; 
        }
        debugPrint('[PurchaseService] Silent cancellation detected.');
        return false;
      }

      // Rethrow with a user-friendly wrapper for actual errors
      throw 'Store Error (${e.code}): ${e.message}';
    } catch (e) {
      debugPrint('[PurchaseService] General Exception during purchase: $e');
      throw e.toString();
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      debugPrint('[PurchaseService] Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      final coachActive = customerInfo.entitlements.all[SubscriptionConfig.entitlementCoachPro]?.isActive ?? false;
      final surferActive = customerInfo.entitlements.all[SubscriptionConfig.entitlementSurferPro]?.isActive ?? false;
      debugPrint('[PurchaseService] Restore complete. Coach: $coachActive, Surfer: $surferActive');
      return coachActive || surferActive;
    } catch (e) {
      debugPrint('[PurchaseService] Restore failed: $e');
      return false;
    }
  }

  @override
  Future<void> openManageSubscriptions() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      var url = customerInfo.managementURL;
      
      // Fallback for iOS if managementURL is not provided by RevenueCat
      url ??= 'https://apps.apple.com/account/subscriptions';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open manage subscriptions: $e');
    }
  }

  @override
  Future<void> logIn(String appUserID) async {
    try {
      debugPrint('[PurchaseService] Logging in user: $appUserID');
      await Purchases.logIn(appUserID);
    } catch (e) {
      debugPrint('[PurchaseService] Error logging in user: $e');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      debugPrint('[PurchaseService] Logging out current user');
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[PurchaseService] Error logging out user: $e');
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
  Future<bool> purchaseCoachPro({String packageId = 'monthly'}) async {
    debugPrint('[LocalSubscriptionService] Simulated purchase Coach Pro ($packageId). (No persistence)');
    return true;
  }

  @override
  Future<bool> purchaseSurferPro({String packageId = 'monthly'}) async {
    debugPrint('[LocalSubscriptionService] Simulated purchase Surfer Pro ($packageId). (No persistence)');
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

  @override
  Future<void> logIn(String appUserID) async {
    debugPrint('[LocalSubscriptionService] Simulated logIn for: $appUserID');
  }

  @override
  Future<void> logOut() async {
    debugPrint('[LocalSubscriptionService] Simulated logOut');
  }
}
