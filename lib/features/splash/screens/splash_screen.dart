import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/core/theme/app_theme.dart';
import 'package:smart_water_reminder/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;

  // These can be overridden in tests to make animation instant/deterministic.
  // Production code always uses the defaults (null → real durations).
  final Duration? introDuration;
  final Duration? exitDuration;
  final Duration? holdDuration;
  final Duration? transitionDuration;
  final Duration? startDelay;

  const SplashScreen({
    super.key,
    required this.next,
    this.introDuration,
    this.exitDuration,
    this.holdDuration,
    this.transitionDuration,
    this.startDelay,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoFill;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _ripple1;
  late final Animation<double> _ripple2;
  late final Animation<double> _ripple3;
  late final Animation<double> _exitFade;
  late final Animation<double> _bgFade;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: widget.introDuration ?? const Duration(milliseconds: 2400),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: widget.exitDuration ?? const Duration(milliseconds: 600),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.85, curve: Curves.fastOutSlowIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(.52, .82, curve: Curves.easeOutCubic),
          ),
        );

    _ripple1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutQuad),
      ),
    );
    _ripple2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuad),
      ),
    );
    _ripple3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOutQuad),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // Give a tiny delay before starting so the engine can render the first frame properly
    Future<void> finishWhenReady() async {
      await _introController.forward().orCancel;
      if (!mounted) return;

      await Future.delayed(widget.holdDuration ?? const Duration(milliseconds: 250));
      if (!mounted) return;

      await _exitController.forward().orCancel;
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => widget.next,
          transitionDuration: widget.transitionDuration ?? const Duration(milliseconds: 700),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .04), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: ScaleTransition(
                  scale: Tween(begin: .98, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    }

    Future.delayed(widget.startDelay ?? const Duration(milliseconds: 100), () {
      if (!mounted) return;
      finishWhenReady();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bgColor,
          ),
      child: Scaffold(
        backgroundColor:
            bgColor, // Base color matches app theme instantly to avoid flashes
        body: FadeTransition(
          opacity: _exitFade,
          child: AnimatedBuilder(
            animation: _introController,
            builder: (context, _) {
              return Stack(
                children: [
                  // Smoothly fade in the gradient background
                  Opacity(
                    opacity: _bgFade.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? AppTheme.waterGradientDark
                              : AppTheme.waterGradientLight,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF7EE8FA).withValues(alpha: .22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _RippleRing(progress: _ripple1.value, maxScale: 2.2),
                  _RippleRing(progress: _ripple2.value, maxScale: 2.7),
                  _RippleRing(progress: _ripple3.value, maxScale: 3.5),
                  _FloatingDroplets(phase: _introController.value),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale:
                                _logoScale.value +
                                math.sin(_introController.value * math.pi * 8) *
                                    0.02,
                            child: RepaintBoundary(
                              child: AppLogo(
                                size: 160,
                                fill: _logoFill.value,
                                wavePhase: _introController.value * math.pi * 6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SlideTransition(
                          position: _textSlide,
                          child: Opacity(
                            opacity: _textOpacity.value,
                            child: Column(
                              children: [
                                Text(
                                  AppConstants.appName,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        height: 1.05,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stay hydrated, stay sharp',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final double progress;
  final double maxScale;

  const _RippleRing({required this.progress, required this.maxScale});

  @override
  Widget build(BuildContext context) {
    if (progress == 0.0) return const SizedBox.shrink();
    return Center(
      child: Opacity(
        opacity: math.max(0, 1 - progress) * 0.32, // Softer ripple
        child: Transform.scale(
          scale: 0.8 + progress * (maxScale - 0.8),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF9BE7FF)
                    .withValues(alpha: 0.8 * (1 - progress)),
                width: 2 - progress,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingDroplets extends StatelessWidget {
  final double phase;

  const _FloatingDroplets({required this.phase});

  @override
  Widget build(BuildContext context) {
    if (phase == 0.0) return const SizedBox.shrink();
    return CustomPaint(
      painter: _DropletPainter(phase: phase),
      size: Size.infinite,
    );
  }
}

class _DropletPainter extends CustomPainter {
  final double phase;

  _DropletPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    const specs = [
      (0.12, 0.18, 3.0, 1.0),
      (0.18, 0.30, 5.0, 1.3),
      (0.28, 0.65, 4.0, 0.9),
      (0.40, 0.22, 6.0, 1.5),
      (0.52, 0.78, 3.0, 1.1),
      (0.65, 0.35, 7.0, 0.8),
      (0.74, 0.55, 4.5, 1.7),
      (0.86, 0.25, 5.5, 1.2),
      (0.90, 0.70, 3.5, 0.95),
      (0.08, 0.52, 2.5, 1.8),
      (0.35, 0.88, 4.0, 0.7),
      (0.78, 0.90, 3.0, 1.6),
    ];

    for (final spec in specs) {
      final drift = math.sin((phase + spec.$4) * math.pi * 2) * 16;
      canvas.drawCircle(
        Offset(size.width * spec.$1, size.height * spec.$2 + drift),
        spec.$3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DropletPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
