import 'package:flutter/material.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../../ui_system/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _startFlow();
  }

  Future<void> _startFlow() async {
    // 1. Fade In
    await _controller.forward();
    
    // 2. Stay for 1 second
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // 3. Fade Out
    await _controller.reverse();
    
    // 4. Finish
    widget.onFinish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary, // Navy
              AppTheme.secondary, // Aqua
            ],
            stops: [0.3, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const SmartSurfWordmark(
  isInverse: true,
  iconSize: 34,
  fontSize: 32,
  spacing: 10,
),
          ),
        ),
      ),
    );
  }
}
