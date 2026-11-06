import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final baseLogoSize = size.width >= mobileMaxWidth
        ? (size.height / 3).clamp(0.0, 320.0)
        : isWindows
        ? (size.width / 2).clamp(0.0, size.height / 3)
        : size.width / 2;
    final logoSize = baseLogoSize * (isWindows ? 0.4 : 1.0);
    if (isWindows) {
      return Image.asset(
        'assets/image/cipherbench-mark.png',
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
      );
    }
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(500),
        border: Border.all(color: AppTheme.logoGreen, width: 2),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: AppTheme.backgroundColors,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.logoGreen.withAlpha(100),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(500),
        child: Image.asset("assets/image/scioly-logo.png", fit: BoxFit.cover),
      ),
      // child: Center(
      //   child: Text(
      //     "SCIOLY\nCODEBUSTERS",
      //     style: TextStyle(
      //       color: AppTheme.logoGreen,
      //       fontSize: 17,
      //       fontFamily: 'JetBrainsMonoBold',
      //       fontWeight: FontWeight.w800,
      //     ),
      //     textAlign: TextAlign.center,
      //   ),
      // ),
    );
  }
}
