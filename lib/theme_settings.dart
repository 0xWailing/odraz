import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:img_syncer/design_tokens.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First run (nothing saved) follows the phone's theme.
AdaptiveThemeMode resolveInitialThemeMode(AdaptiveThemeMode? saved) =>
    saved ?? AdaptiveThemeMode.system;

/// The dark theme: warm black, or pure black when [oled] is on.
ThemeData buildDarkThemeData({Color? userSeed, required bool oled}) =>
    buildThemeData(
      colorScheme: resolveColorScheme(
        userSeed: userSeed,
        brightness: Brightness.dark,
        oled: oled,
      ),
      brightness: Brightness.dark,
    );

/// Saves the OLED choice and rebuilds the dark theme right away.
Future<void> applyOledDark(BuildContext context, bool value) async {
  oledDark = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('oled_dark', value);
  if (!context.mounted) return;
  final manager = AdaptiveTheme.of(context);
  manager.setTheme(
    light: manager.lightTheme,
    dark: buildDarkThemeData(userSeed: seedColor, oled: value),
  );
}

/// The "Theme" row (System / Light / Dark) and the pure-black switch.
class ThemeSettingsTiles extends StatefulWidget {
  const ThemeSettingsTiles({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsTiles> createState() => _ThemeSettingsTilesState();
}

class _ThemeSettingsTilesState extends State<ThemeSettingsTiles> {
  String _label(AdaptiveThemeMode mode) {
    switch (mode) {
      case AdaptiveThemeMode.light:
        return l10n.themeLight;
      case AdaptiveThemeMode.dark:
        return l10n.themeDark;
      case AdaptiveThemeMode.system:
        return l10n.themeSystem;
    }
  }

  void _pickMode() {
    final manager = AdaptiveTheme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: RadioGroup<AdaptiveThemeMode>(
          groupValue: manager.mode,
          onChanged: (mode) {
            if (mode == null) return;
            manager.setThemeMode(mode);
            Navigator.pop(dialogContext);
            setState(() {});
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(30, 20, 20, 5),
                child: Text(l10n.themeTitle,
                    style: Theme.of(dialogContext).textTheme.titleLarge),
              ),
              for (final mode in AdaptiveThemeMode.values)
                RadioListTile<AdaptiveThemeMode>(
                  value: mode,
                  title: Text(_label(mode)),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingSmall),
          child: ListTile(
            leading: Icon(Icons.brightness_6_outlined,
                size: 28, color: cs.onSurfaceVariant),
            title: Text(l10n.themeTitle, style: tt.titleLarge),
            subtitle: Text(_label(AdaptiveTheme.of(context).mode),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            onTap: _pickMode,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingSmall),
          child: SwitchListTile(
            secondary:
                Icon(Icons.contrast, size: 28, color: cs.onSurfaceVariant),
            title: Text(l10n.themeOled, style: tt.titleLarge),
            subtitle: Text(l10n.themeOledDesc,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            value: oledDark,
            onChanged: (value) async {
              await applyOledDark(context, value);
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
