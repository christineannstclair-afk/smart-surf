import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class LegalUtils {
  static const String appleEulaUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String privacyPolicyUrl = 'https://docs.google.com/document/d/e/2PACX-1vS-V7qRKKRNjIXCoL5SkMfj2qZpb461689o6o7B-8u8O-2zN76QTDyKY60h90pJpZcIR96bEenVgdcw/pub';

  static Future<void> openTermsOfUse() async {
    await _launchURL(appleEulaUrl);
  }

  static Future<void> openPrivacyPolicy() async {
    await _launchURL(privacyPolicyUrl);
  }

  static Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    // Use LaunchMode.externalApplication to ensure links open in Safari/Chrome
    // rather than an in-app webview which can sometimes render Apple's EULA blank.
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // Common footer text builder to ensure consistency across screens
  static Widget buildLegalFooter({
    required BuildContext context,
    required bool isSpanish,
    Color? color,
    double fontSize = 11,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = color ?? colorScheme.onSurfaceVariant.withOpacity(0.6);
    final linkColor = Theme.of(context).colorScheme.primary;

    String t(String en, String es) => isSpanish ? es : en;

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            height: 1.4,
            fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
          ),
          children: [
            TextSpan(
              text: t("By continuing, you agree to our ", "Al continuar, aceptas nuestros "),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: openTermsOfUse,
                child: Text(
                  t("Terms of Use", "Términos de Uso"),
                  style: TextStyle(
                    color: linkColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: t(" and ", " y "),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: openPrivacyPolicy,
                child: Text(
                  t("Privacy Policy", "Política de Privacidad"),
                  style: TextStyle(
                    color: linkColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
            const TextSpan(text: "."),
          ],
        ),
      ),
    );
  }
}
