import 'package:flutter/material.dart';
import '../../core/translation_service.dart';

class GuidedTourOverlay extends StatelessWidget {
  final Rect targetRect;
  final String title;
  final String description;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isSpanish;
  final bool isLastStep;

  const GuidedTourOverlay({
    super.key,
    required this.targetRect,
    required this.title,
    required this.description,
    required this.nextLabel,
    required this.onNext,
    required this.onSkip,
    this.isSpanish = false,
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Determine callout position
    final bool isTopHalf = targetRect.center.dy < size.height / 2;
    final double? calloutTop = isTopHalf ? targetRect.bottom + 20 : null;
    final double? calloutBottom = isTopHalf ? null : (size.height - targetRect.top) + 20;

    return Stack(
      children: [
        // Dark overlay with hole
        GestureDetector(
          onTap: onNext,
          child: CustomPaint(
            size: Size.infinite,
            painter: _SpotlightPainter(targetRect: targetRect),
          ),
        ),

        // Callout
        PositionNotifier(
          top: calloutTop,
          bottom: calloutBottom,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isTopHalf) _Arrow(isUp: false),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: onSkip,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: onSkip,
                            child: Text(TranslationService().translate("onboarding_skip_tour", isSpanish)),
                          ),
                          FilledButton(
                            onPressed: onNext,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(nextLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isTopHalf) _Arrow(isUp: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;

  _SpotlightPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        targetRect.inflate(8),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw a thin highlight border around the hole
    final borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(8),
        const Radius.circular(12),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => 
      targetRect != oldDelegate.targetRect;
}

class _Arrow extends StatelessWidget {
  final bool isUp;
  const _Arrow({required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 10,
      child: CustomPaint(
        painter: _TrianglePainter(isUp: isUp),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final bool isUp;
  _TrianglePainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    if (isUp) {
      path.moveTo(0, 10);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, 10);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, 10);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PositionNotifier extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Widget child;

  const PositionNotifier({
    super.key,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
