import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'Smart Data Organizer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 450),
              child: const Text(
                'AI-Powered Data Cleaner',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.7),
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
