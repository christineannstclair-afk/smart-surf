import 'package:flutter/material.dart';
import '../../ui_system/app_theme.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String content;

  const LegalPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTheme.themeData.textTheme.titleLarge),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: AppTheme.themeData.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  final bool isSpanish;

  const PrivacyPolicyPage({super.key, required this.isSpanish});

  String _t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final title = _t('Privacy Policy', 'Política de Privacidad');
    final content = _t(
      '''Smart Surf Privacy Policy
Last updated: March 2026

Smart Surf respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how information is collected, used, and stored when you use the Smart Surf application.

Information We Collect

Smart Surf may collect and store the following information to provide the app’s features:

• Surf session details (wave height, board type, conditions, duration)
• Reflections or notes you enter about your surf sessions
• Media you upload (photos or short clips)
• App usage data related to sessions and progress tracking

This information is used only to provide surf insights, track progress, and improve the app experience.

AI Surf Insights

Smart Surf may use artificial intelligence to generate feedback based on your logged surf sessions and reflections.

These insights are designed to support learning and personal reflection. They are not a replacement for advice from a professional surf coach.

How Your Data Is Used

Your data is used to:

• Generate surf insights
• Track your surf history and progress
• Display your surf passport and session statistics
• Improve the functionality of the Smart Surf app

Your data is not sold or shared with third parties for advertising or marketing purposes.

Data Storage

Session data and app preferences may be stored locally on your device or securely in app databases to allow you to view your surf history and insights.

Media Uploads

If you upload photos or clips to a session, those files are stored only for use within your Smart Surf history.

Children’s Privacy

Smart Surf is not specifically directed toward children under the age of 13.

Changes to This Policy

This Privacy Policy may be updated as the app evolves.

Contact

For questions about this policy contact:

smartsurfapp.help@gmail.com''',
      '''Política de Privacidad de Smart Surf
Última actualización: marzo de 2026

Smart Surf respeta su privacidad y se compromete a proteger su información personal. Esta Política de Privacidad explica cómo se recopila, utiliza y almacena la información cuando utiliza la aplicación Smart Surf.

Información que Recopilamos

Smart Surf puede recopilar y almacenar la siguiente información para proporcionar las funciones de la aplicación:

• Detalles de la sesión de surf (altura de la ola, tipo de tabla, condiciones, duración)
• Reflexiones o notas que ingrese sobre sus sesiones de surf
• Contenido multimedia que suba (fotos o clips cortos)
• Datos de uso de la aplicación relacionados con las sesiones y el seguimiento del progreso

Esta información se utiliza únicamente para proporcionar perspectivas de surf, realizar un seguimiento del progreso y mejorar la experiencia de la aplicación.

Perspectivas de Surf con IA

Smart Surf puede utilizar inteligencia artificial para generar comentarios basados en sus sesiones de surf registradas y reflexiones.

Estas perspectivas están diseñadas para apoyar el aprendizaje y la reflexión personal. No son un sustituto del consejo de un entrenador de surf profesional.

Cómo se Utilizan sus Datos

Sus datos se utilizan para:

• Generar perspectivas de surf
• Realizar un seguimiento de su historial de surf y progreso
• Mostrar su pasaporte de surf y estadísticas de sesión
• Mejorar la funcionalidad de la aplicación Smart Surf

Sus datos no se venden ni se comparten con terceros con fines publicitarios o de marketing.

Almacenamiento de Datos

Los datos de la sesión y las preferencias de la aplicación pueden almacenarse localmente en su dispositivo o de forma segura en las bases de datos de la aplicación para permitirle ver su historial de surf e insights.

Carga de Contenido multimedia

Si sube fotos o clips a una sesión, esos archivos se almacenan únicamente para su uso dentro de su historial de Smart Surf.

Privacidad Infantil

Smart Surf no está dirigido específicamente a niños menores de 13 años.

Cambios en esta Política

Esta Política de Privacidad puede actualizarse a medida que la aplicación evoluciona.

Contacto

Para preguntas sobre esta política, contacte a:

smartsurfapp.help@gmail.com''',
    );

    return LegalPage(title: title, content: content);
  }
}

class TermsOfUsePage extends StatelessWidget {
  final bool isSpanish;

  const TermsOfUsePage({super.key, required this.isSpanish});

  String _t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final title = _t('Terms of Use', 'Términos de Uso');
    final content = _t(
      '''Smart Surf Terms of Use
Last updated: March 2026

Welcome to Smart Surf. By using the Smart Surf application you agree to these Terms of Use.

Use of the App

Smart Surf helps surfers log sessions, reflect on their surfing, and track progress over time.

User Content

You may enter session notes, reflections, surf spot information, and upload photos or clips. You are responsible for the content you upload.

AI Surf Insights

Smart Surf may generate AI-based insights from your session data. These insights are meant to support learning and reflection and do not replace feedback from a professional surf coach.

No Guarantee of Results

Smart Surf does not guarantee surfing improvement or performance outcomes.

Accounts and Access

Future features may include accounts or subscriptions. Users are responsible for protecting login information.

Paid Features

If subscriptions or purchases are offered, pricing and billing terms will be clearly displayed before purchase.

Intellectual Property

The Smart Surf application, branding, and design are owned by Smart Surf.

Changes to the App

Features may evolve or change as the app improves.

Limitation of Liability

Smart Surf is provided as-is without warranties.

Contact

smartsurfapp.help@gmail.com''',
      '''Términos de Uso de Smart Surf
Última actualización: marzo de 2026

Bienvenido a Smart Surf. Al utilizar la aplicación Smart Surf, usted acepta estos Términos de Uso.

Uso de la Aplicación

Smart Surf ayuda a los surfistas a registrar sesiones, reflexionar sobre su surf y realizar un seguimiento del progreso a lo largo del tiempo.

Contenido del Usuario

Puede ingresar notas de sesión, reflexiones, información sobre spots de surf y subir fotos o clips. Usted es responsable del contenido que suba.

Perspectivas de Surf con IA

Smart Surf puede generar perspectivas basadas en IA a partir de los datos de su sesión. Estas perspectivas están destinadas a apoyar el aprendizaje y la reflexión, y no reemplazan los comentarios de un entrenador de surf profesional.

Sin Garantía de Resultados

Smart Surf no garantiza mejoras en el surf ni resultados de rendimiento.

Cuentas y Acceso

Las funciones futuras pueden incluir cuentas o suscripciones. Los usuarios son responsables de proteger la información de inicio de sesión.

Funciones de Pago

Si se ofrecen suscripciones o compras, los precios y los términos de facturación se mostrarán claramente antes de la compra.

Propiedad Intelectual

La aplicación Smart Surf, la marca y el diseño son propiedad de Smart Surf.

Cambios en la Aplicación

Las funciones pueden evolucionar o cambiar a medida que la aplicación mejora.

Limitación de Responsabilidad

Smart Surf se proporciona "tal cual" sin garantías.

Contacto

smartsurfapp.help@gmail.com''',
    );

    return LegalPage(title: title, content: content);
  }
}
