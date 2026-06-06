import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/core/bundeswehr_theme.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/widgets/bundeswehr_logo.dart';
import 'package:mobile_app/widgets/bundeswehr_camouflage_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(Routes.login);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BundeswehrTheme.olive900,
      body: BundeswehrCamouflageBackground(
        dark: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              BundeswehrLogo(size: 190),
              SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'BUNDESWEHR',
                  style: TextStyle(
                    color: BundeswehrTheme.white,
                    fontSize: 44,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: BundeswehrTheme.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
