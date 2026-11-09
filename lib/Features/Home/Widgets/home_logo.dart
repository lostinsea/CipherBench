import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final baseLogoSize = size.width >= mobileMaxWidth
        ? (size.height / 3).clamp(0.0, 320.0)
        : (size.width / 2).clamp(0.0, size.height / 3);
    final logoSize = baseLogoSize * 0.4;
    return Image.asset(
      'assets/image/cipherbench-mark.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
    );
  }
}
