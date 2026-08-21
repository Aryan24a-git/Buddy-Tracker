import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/routing/app_router.dart';
import '../widgets/web_geometry_painter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/providers/service_providers.dart';

/// Splash screen — design.md §6.
/// Spider-web geometry background + 🕷 BUDDY TRACKER wordmark.
/// Auto-navigates to Dashboard or Onboarding after a short delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Check user and navigate
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      
      final db = ref.read(databaseProvider);
      final user = await db.usersDao.getFirstUser();
      
      if (mounted) {
        if (user != null) {
          context.go(AppRoutes.dashboard);
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Web geometry background ───────────────────────────────────
          CustomPaint(
            painter: const WebGeometryPainter(rings: 8, spokes: 12),
          ),

          // ── Centered wordmark ─────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Spider glyph
                    const Text(
                      '🕷',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),

                    // App wordmark
                    Text(
                      'BUDDY TRACKER',
                      style: AppTextStyles.splashLogo,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'SPIDER-SENSE FOR CAMPUS',
                      style: AppTextStyles.radarLabel.copyWith(
                        color: AppColors.whiteMuted,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom loading dot ────────────────────────────────────────
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeIn,
              child: const _PulsingDot(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle pulsing dot at the bottom of the splash screen.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.electricBlue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
