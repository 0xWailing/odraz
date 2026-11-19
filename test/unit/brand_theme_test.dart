import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:img_syncer/design_tokens.dart';
import 'package:img_syncer/theme.dart';

double _lum(Color c) => c.computeLuminance();

/// WCAG contrast ratio between two colors.
double contrast(Color a, Color b) {
  final hi = math.max(_lum(a), _lum(b));
  final lo = math.min(_lum(a), _lum(b));
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('brand color schemes', () {
    test('light brand scheme uses the palette', () {
      final cs = buildBrandColorScheme(Brightness.light);
      expect(cs.primary, AppColors.brandViolet);
      expect(cs.secondary, AppColors.brandBlue);
      expect(cs.tertiary, AppColors.brandCyan);
      expect(cs.surface, AppColors.brandSnow);
      expect(cs.onSurface, AppColors.brandInk);
    });

    test('dark brand scheme uses the palette', () {
      final cs = buildBrandColorScheme(Brightness.dark);
      expect(cs.primary, AppColors.brandCyan);
      expect(cs.secondary, AppColors.brandViolet);
      expect(cs.tertiary, AppColors.brandBlue);
      expect(cs.surface, AppColors.brandNight);
      expect(cs.onSurface, AppColors.brandSnow);
    });

    for (final b in [Brightness.light, Brightness.dark]) {
      test('brand pairs are readable ($b)', () {
        final cs = buildBrandColorScheme(b);
        expect(contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onSecondary, cs.secondary),
            greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onTertiary, cs.tertiary),
            greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(7));
      });
    }

    test('a saved seed color overrides the brand default', () {
      final custom = resolveColorScheme(
          userSeed: const Color(0xFFFF2C55), brightness: Brightness.light);
      expect(custom.primary, isNot(AppColors.brandViolet));
      final branded = resolveColorScheme(
          userSeed: null, brightness: Brightness.light);
      expect(branded, buildBrandColorScheme(Brightness.light));
    });

    test('default seed color is the brand violet', () {
      expect(seedThemeColors[0], AppColors.brandViolet);
    });
  });
}
