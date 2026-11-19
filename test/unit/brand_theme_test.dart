import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:img_syncer/design_tokens.dart';
import 'package:img_syncer/theme.dart';

/// WCAG contrast ratio between two colors.
double contrast(Color a, Color b) {
  final hi = math.max(a.computeLuminance(), b.computeLuminance());
  final lo = math.min(a.computeLuminance(), b.computeLuminance());
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('brand color schemes', () {
    test('light scheme uses the warm palette', () {
      final cs = buildBrandColorScheme(Brightness.light);
      expect(cs.surface, const Color(0xFFFAF8F2));
      expect(cs.surfaceContainerLow, const Color(0xFFFDFCF7));
      expect(cs.surfaceContainer, const Color(0xFFF7F4ED));
      expect(cs.surfaceContainerHighest, const Color(0xFFEDE8DC));
      expect(cs.onSurface, const Color(0xFF0A0A0B));
      expect(cs.onSurfaceVariant, const Color(0xFF6B6457));
      expect(cs.outlineVariant, const Color(0xFFE8E3D8));
      expect(cs.primary, AppColors.brandViolet);
      expect(cs.secondary, AppColors.brandBlue);
      expect(cs.tertiary, AppColors.brandCyan);
    });

    test('dark scheme uses the warm palette', () {
      final cs = buildBrandColorScheme(Brightness.dark);
      expect(cs.surface, const Color(0xFF0C0B09));
      expect(cs.surfaceContainerLow, const Color(0xFF161512));
      expect(cs.surfaceContainer, const Color(0xFF1C1B17));
      expect(cs.surfaceContainerHighest, const Color(0xFF2B2A24));
      expect(cs.onSurface, const Color(0xFFEDEDEE));
      expect(cs.onSurfaceVariant, const Color(0xFFA0A0A6));
      expect(cs.outlineVariant, const Color(0xFF2A2924));
      expect(cs.primary, const Color(0xFFA78BFA));
      expect(cs.onPrimary, const Color(0xFF0B0817));
      expect(cs.secondary, AppColors.brandBlue);
      expect(cs.tertiary, AppColors.brandCyan);
    });

    test('oled scheme is pure black', () {
      final cs = buildBrandColorScheme(Brightness.dark, oled: true);
      final dark = buildBrandColorScheme(Brightness.dark);
      expect(cs.surface, const Color(0xFF000000));
      expect(cs.surfaceContainerLow, const Color(0xFF0A0A0A));
      expect(cs.surfaceContainer, const Color(0xFF121212));
      expect(cs.surfaceContainerHighest, const Color(0xFF222222));
      expect(cs.outlineVariant, const Color(0xFF242424));
      expect(cs.primary, dark.primary);
      expect(cs.onSurface, dark.onSurface);
      expect(buildBrandColorScheme(Brightness.light, oled: true),
          buildBrandColorScheme(Brightness.light));
    });

    for (final entry in {
      'light': buildBrandColorScheme(Brightness.light),
      'dark': buildBrandColorScheme(Brightness.dark),
      'oled': buildBrandColorScheme(Brightness.dark, oled: true),
    }.entries) {
      test('readable pairs (${entry.key})', () {
        final cs = entry.value;
        expect(contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onSecondary, cs.secondary),
            greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onTertiary, cs.tertiary),
            greaterThanOrEqualTo(4.5));
        expect(contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(7));
        expect(contrast(cs.onSurfaceVariant, cs.surface),
            greaterThanOrEqualTo(4.5));
      });
    }

    test('a saved seed color overrides the brand default in both modes', () {
      const seed = Color(0xFFFF2C55);
      final light =
          resolveColorScheme(userSeed: seed, brightness: Brightness.light);
      final dark =
          resolveColorScheme(userSeed: seed, brightness: Brightness.dark);
      expect(light.primary, isNot(AppColors.brandViolet));
      expect(dark.primary, isNot(const Color(0xFFA78BFA)));
      expect(
          resolveColorScheme(
                  userSeed: seed, brightness: Brightness.dark, oled: true)
              .surface,
          const Color(0xFF000000));
      expect(resolveColorScheme(userSeed: null, brightness: Brightness.light),
          buildBrandColorScheme(Brightness.light));
      expect(
          resolveColorScheme(
              userSeed: null, brightness: Brightness.dark, oled: true),
          buildBrandColorScheme(Brightness.dark, oled: true));
    });

    test('default seed color is the brand violet', () {
      expect(seedThemeColors[0], AppColors.brandViolet);
    });
  });
}
