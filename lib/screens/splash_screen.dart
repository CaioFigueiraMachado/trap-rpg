import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      // Vai para a Home se já houver sessão salva; senão, para o login.
      context.go(AuthService.isLoggedIn ? AppRoutes.home : AppRoutes.login);
    });
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pré-carrega a logo e as artes das cartas enquanto a abertura toca.
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage('lib/assets/logo.webp'), context);
    for (final id in const [
      'alee', 'matue', 'teto', 'klisman', 'leviano',
      'phlnoturnboy', 'fabgodamn', 'reid', 'stef', 'fabin',
    ]) {
      precacheImage(AssetImage('lib/assets/cards/$id.webp'), context);
    }
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
          gradient: RadialGradient(
            colors: [Color(0xFF2E1065), AppColors.bg],
            radius: 1.1,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: Breakpoints.isTablet(context) ? 300 : 220),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.accent,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
