/// 应用设计 Token：从各文件中提取的共享颜色、圆角、间距常量。
///
/// 所有值均为 `static const`，可在 `const` 上下文中使用。
/// 每个类拥有私有构造函数以防止实例化。
///
/// 来源：
/// - [AppColors] 提取自 theme.dart, gallery_viewer_route.dart,
///   sync_body.dart, gallery_body.dart, video_route.dart
/// - [AppRadius] 提取自 theme.dart
/// - [AppSpacing] 提取自多个 UI 文件
library;

import 'package:flutter/material.dart';

/// 应用中常用的颜色常量。
class AppColors {
  AppColors._();

  /// odraz brand palette, sampled from the logo.
  static const Color brandViolet = Color(0xFF6B4FD8);
  static const Color brandBlue = Color(0xFF4D96FF);
  static const Color brandCyan = Color(0xFF4DDCFF);
  static const Color brandInk = Color(0xFF111827);
  static const Color brandSnow = Color(0xFFF9FAFB);
  static const Color brandNight = Color(0xFF180448);

  /// Warm neutrals (after whaling.xyz): light "paper" surfaces.
  static const Color paperSurface = Color(0xFFFAF8F2);
  static const Color paperLowest = Color(0xFFFFFFFF);
  static const Color paperLow = Color(0xFFFDFCF7);
  static const Color paperContainer = Color(0xFFF7F4ED);
  static const Color paperHigh = Color(0xFFF2EEE4);
  static const Color paperHighest = Color(0xFFEDE8DC);
  static const Color paperDim = Color(0xFFE9E4D8);
  static const Color paperMutedText = Color(0xFF6B6457);
  static const Color paperOutline = Color(0xFF8A8272);
  static const Color paperHairline = Color(0xFFE8E3D8);

  /// Warm neutrals: dark "ink" surfaces.
  static const Color inkSurface = Color(0xFF0C0B09);
  static const Color inkLow = Color(0xFF161512);
  static const Color inkContainer = Color(0xFF1C1B17);
  static const Color inkHigh = Color(0xFF23221D);
  static const Color inkHighest = Color(0xFF2B2A24);
  static const Color inkText = Color(0xFFEDEDEE);
  static const Color inkMutedText = Color(0xFFA0A0A6);
  static const Color inkOutline = Color(0xFF6E6D68);
  static const Color inkHairline = Color(0xFF2A2924);
  static const Color inkPrimary = Color(0xFFA78BFA);
  static const Color inkOnAccent = Color(0xFF0B0817);

  /// OLED: pure black with slightly lifted containers.
  static const Color oledSurface = Color(0xFF000000);
  static const Color oledLow = Color(0xFF0A0A0A);
  static const Color oledContainer = Color(0xFF121212);
  static const Color oledHigh = Color(0xFF1A1A1A);
  static const Color oledHighest = Color(0xFF222222);
  static const Color oledHairline = Color(0xFF242424);

  /// Pro 功能的皇冠图标金色 (#EACD76)
  static const Color proCrownColor = Color.fromARGB(255, 234, 205, 118);

  /// 购买页背景绿色 (#00A385)
  static const Color buyPageBackground = Color.fromARGB(255, 0, 163, 133);

  /// 视频路线页背景灰色 (#525252)
  static const Color videoRouteBg = Color.fromARGB(255, 82, 82, 82);
}

/// 应用中常用的圆角常量，遵循 Material 3 形状比例。
class AppRadius {
  AppRadius._();

  /// M3 形状比例：极小圆角 (4.0)
  static const double extraSmall = 4.0;

  /// M3 形状比例：小圆角 (8.0)
  static const double small = 8.0;

  /// M3 形状比例：中圆角 (12.0)
  static const double medium = 12.0;

  /// M3 形状比例：大圆角 (16.0)
  static const double large = 16.0;

  /// M3 形状比例：超大圆角 (28.0)
  static const double extraLarge = 28.0;

  /// 全圆角按钮圆角值 (20.0)
  static const double buttonFull = 20.0;
}

/// 应用中常用的间距常量，遵循 Material 3 间距比例。
class AppSpacing {
  AppSpacing._();

  /// 标准内边距 (15.0)
  static const double paddingStandard = 15.0;

  /// 小内边距 (10.0)
  static const double paddingSmall = 10.0;

  /// 大内边距 (20.0)
  static const double paddingLarge = 20.0;

  /// M3 间距比例：极小 (4.0)
  static const double xs = 4.0;

  /// M3 间距比例：小 (8.0)
  static const double sm = 8.0;

  /// M3 间距比例：中 (16.0)
  static const double md = 16.0;

  /// M3 间距比例：大 (24.0)
  static const double lg = 24.0;

  /// M3 间距比例：超大 (32.0)
  static const double xl = 32.0;
}
