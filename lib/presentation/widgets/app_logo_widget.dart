import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;

  const AppLogoWidget({
    super.key,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
