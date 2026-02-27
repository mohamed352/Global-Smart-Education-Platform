import 'package:flutter/material.dart';

class TalkingAvatarWidget extends StatefulWidget {
  const TalkingAvatarWidget({
    super.key,
    required this.size,
    this.isSpeaking = false,
  });

  final double size;
  final bool isSpeaking;

  @override
  State<TalkingAvatarWidget> createState() => _TalkingAvatarWidgetState();
}

class _TalkingAvatarWidgetState extends State<TalkingAvatarWidget>
    with TickerProviderStateMixin {
  // Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Mouth open/close (talking)
  late AnimationController _mouthController;
  late Animation<double> _mouthAnimation;

  // Blink
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Nod
  late AnimationController _nodController;
  late Animation<double> _nodAnimation;

  // Tilt
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _mouthAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _nodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _nodAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _nodController, curve: Curves.easeInOut));

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _tiltAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
    );

    _startBlinkLoop();
    _startMicroMovements();

    if (widget.isSpeaking) {
      _startSpeaking();
    }
  }

  @override
  void didUpdateWidget(covariant TalkingAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _startSpeaking();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _stopSpeaking();
    }
  }

  void _startSpeaking() {
    _mouthController.repeat(reverse: true);
  }

  void _stopSpeaking() {
    _mouthController.stop();
    _mouthController.reset();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future<void>.delayed(
        Duration(
          milliseconds: 3000 + (1000 * (DateTime.now().millisecond % 5)),
        ),
      );
      if (!mounted) return;
      await _blinkController.forward();
      await _blinkController.reverse();
    }
  }

  void _startMicroMovements() {
    if (mounted) {
      _nodController.repeat(reverse: true);
      _tiltController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mouthController.dispose();
    _blinkController.dispose();
    _nodController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double s = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _glowAnimation,
        _mouthAnimation,
        _blinkAnimation,
        _nodAnimation,
        _tiltAnimation,
      ]),
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Glow
            if (widget.isSpeaking)
              Container(
                width: s * 1.2,
                height: s * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.1 + _glowAnimation.value * 0.2,
                      ),
                      blurRadius: 15 + _glowAnimation.value * 15,
                      spreadRadius: 2 + _glowAnimation.value * 5,
                    ),
                  ],
                ),
              ),
            // Avatar Body and Face
            Transform.translate(
              offset: Offset(0, _nodAnimation.value * s),
              child: Transform.rotate(
                angle: _tiltAnimation.value,
                child: SizedBox(
                  width: s,
                  height: s,
                  child: CustomPaint(
                    painter: _AdvancedAvatarPainter(
                      mouthOpen: widget.isSpeaking
                          ? _mouthAnimation.value
                          : 0.1,
                      eyeOpenness: _blinkAnimation.value,
                      primaryColor: theme.colorScheme.primary,
                      secondaryColor: theme.colorScheme.secondary,
                      tertiaryColor: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdvancedAvatarPainter extends CustomPainter {
  _AdvancedAvatarPainter({
    required this.mouthOpen,
    required this.eyeOpenness,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  final double mouthOpen;
  final double eyeOpenness;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final Paint skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    final Paint darkSkinPaint = Paint()..color = const Color(0xFFE0AC69);
    final Paint hairPaint = Paint()..color = const Color(0xFF2D2926);
    final Paint clothesPaint = Paint()..color = primaryColor;
    final Paint whitePaint = Paint()..color = Colors.white;

    // 1. Shoulders/Clothes
    final Path clothesPath = Path();
    clothesPath.moveTo(cx - r * 0.8, size.height);
    clothesPath.quadraticBezierTo(
      cx - r * 0.7,
      size.height - r * 0.3,
      cx - r * 0.2,
      size.height - r * 0.2,
    );
    clothesPath.lineTo(cx + r * 0.2, size.height - r * 0.2);
    clothesPath.quadraticBezierTo(
      cx + r * 0.7,
      size.height - r * 0.3,
      cx + r * 0.8,
      size.height,
    );
    clothesPath.close();
    canvas.drawPath(clothesPath, clothesPaint);

    // 2. Neck
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, size.height - r * 0.25),
        width: r * 0.25,
        height: r * 0.2,
      ),
      darkSkinPaint,
    );

    // 3. Face Shape
    final Path facePath = Path();
    facePath.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy - r * 0.05),
        width: r * 0.85,
        height: r * 1.05,
      ),
    );
    canvas.drawPath(facePath, skinPaint);

    // 5. Eyes
    final double eyeY = cy - r * 0.15;
    final double eyeSpacing = r * 0.22;
    final double eyeW = r * 0.18;
    final double eyeH = r * 0.12 * eyeOpenness;

    // Eye sockets/shadows
    final Paint eyeShadow = Paint()
      ..color = darkSkinPaint.color.withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeSpacing, eyeY),
        width: eyeW * 1.2,
        height: r * 0.15,
      ),
      eyeShadow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeSpacing, eyeY),
        width: eyeW * 1.2,
        height: r * 0.15,
      ),
      eyeShadow,
    );

    // Eyeballs
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeSpacing, eyeY),
        width: eyeW,
        height: eyeH.clamp(1.0, r * 0.12),
      ),
      whitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeSpacing, eyeY),
        width: eyeW,
        height: eyeH.clamp(1.0, r * 0.12),
      ),
      whitePaint,
    );

    // Pupils
    if (eyeOpenness > 0.4) {
      final Paint pupilPaint = Paint()..color = Colors.black87;
      canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeW * 0.25, pupilPaint);
      canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeW * 0.25, pupilPaint);

      // Reflection
      canvas.drawCircle(Offset(cx - eyeSpacing - 2, eyeY - 2), 2, whitePaint);
      canvas.drawCircle(Offset(cx + eyeSpacing - 2, eyeY - 2), 2, whitePaint);
    }

    // 6. Mouth
    final double mouthY = cy + r * 0.25;
    final double mouthW = r * 0.25;
    final double mouthH = r * 0.05 + (mouthOpen * r * 0.15);

    final Paint lipPaint = Paint()..color = const Color(0xFFC87D7D);
    final Paint mouthInsidePaint = Paint()..color = const Color(0xFF4A1A1A);

    // Mouth Background
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mouthY),
        width: mouthW,
        height: mouthH,
      ),
      mouthInsidePaint,
    );

    // Lips
    canvas.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY - mouthH / 2),
          width: mouthW * 1.1,
          height: 4,
        ),
      ),
      lipPaint,
    );
    canvas.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + mouthH / 2),
          width: mouthW * 0.9,
          height: 3,
        ),
      ),
      lipPaint,
    );

    // 7. Hair (Front)
    final Path hairPath = Path();
    hairPath.moveTo(cx - r * 0.45, cy - r * 0.55);
    hairPath.quadraticBezierTo(cx, cy - r * 0.7, cx + r * 0.45, cy - r * 0.55);
    hairPath.quadraticBezierTo(
      cx + r * 0.55,
      cy - r * 0.1,
      cx + r * 0.45,
      cy + r * 0.2,
    );
    hairPath.lineTo(cx - r * 0.45, cy + r * 0.2);
    hairPath.quadraticBezierTo(
      cx - r * 0.55,
      cy - r * 0.1,
      cx - r * 0.45,
      cy - r * 0.55,
    );
    canvas.drawPath(hairPath, hairPaint);

    // Forehead hair
    final Path bangs = Path();
    bangs.moveTo(cx - r * 0.45, cy - r * 0.5);
    bangs.quadraticBezierTo(cx - r * 0.2, cy - r * 0.55, cx, cy - r * 0.4);
    bangs.quadraticBezierTo(
      cx + r * 0.2,
      cy - r * 0.55,
      cx + r * 0.45,
      cy - r * 0.5,
    );
    canvas.drawPath(bangs, hairPaint);

    // 8. Glasses
    final Paint glassesFrame = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double gSize = r * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - eyeSpacing, eyeY),
          width: gSize,
          height: gSize * 0.8,
        ),
        const Radius.circular(8),
      ),
      glassesFrame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + eyeSpacing, eyeY),
          width: gSize,
          height: gSize * 0.8,
        ),
        const Radius.circular(8),
      ),
      glassesFrame,
    );
    // Bridge
    canvas.drawLine(
      Offset(cx - eyeSpacing + gSize / 2, eyeY),
      Offset(cx + eyeSpacing - gSize / 2, eyeY),
      glassesFrame,
    );
  }

  @override
  bool shouldRepaint(covariant _AdvancedAvatarPainter oldDelegate) {
    return oldDelegate.mouthOpen != mouthOpen ||
        oldDelegate.eyeOpenness != eyeOpenness;
  }
}
