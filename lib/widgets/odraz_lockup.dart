import 'package:flutter/material.dart';

/// The odraz mark with the "odraz" wordmark, picking the variant that reads on
/// the current theme's background.
class OdrazLockup extends StatelessWidget {
  const OdrazLockup({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark
          ? 'assets/branding/odraz_lockup_dark.png'
          : 'assets/branding/odraz_lockup_light.png',
      height: height,
      semanticLabel: 'odraz',
    );
  }
}
