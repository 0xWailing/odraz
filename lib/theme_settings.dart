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

/// What the user picks in Settings. OLED is dark mode with pure-black surfaces.
enum ThemeChoice { system, light, dark, oled }

ThemeChoice themeChoiceOf(AdaptiveThemeMode mode, bool oled) {
  switch (mode) {
    case AdaptiveThemeMode.light:
      return ThemeChoice.light;
    case AdaptiveThemeMode.dark:
      return oled ? ThemeChoice.oled : ThemeChoice.dark;
    case AdaptiveThemeMode.system:
      return ThemeChoice.system;
  }
}

/// OLED only counts when dark is the chosen mode. Version 1.1 had OLED as a
/// switch on top of System; that leftover flag is dropped at startup.
bool resolveOledFlag({
  required bool savedOled,
  required AdaptiveThemeMode? savedMode,
}) =>
    savedOled && savedMode == AdaptiveThemeMode.dark;

/// Applies a choice: sets the mode, saves the OLED flag and rebuilds the dark
/// theme right away.
Future<void> applyThemeChoice(BuildContext context, ThemeChoice choice) async {
  oledDark = choice == ThemeChoice.oled;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('oled_dark', oledDark);
  if (!context.mounted) return;
  final manager = AdaptiveTheme.of(context);
  manager.setTheme(
    light: manager.lightTheme,
    dark: buildDarkThemeData(userSeed: seedColor, oled: oledDark),
  );
  switch (choice) {
    case ThemeChoice.system:
      manager.setSystem();
      break;
    case ThemeChoice.light:
      manager.setLight();
      break;
    case ThemeChoice.dark:
    case ThemeChoice.oled:
      manager.setDark();
      break;
  }
}

/// The "Theme" row: System / Light / Dark / OLED.
class ThemeSettingsTiles extends StatefulWidget {
  const ThemeSettingsTiles({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsTiles> createState() => _ThemeSettingsTilesState();
}

class _ThemeSettingsTilesState extends State<ThemeSettingsTiles> {
  String _label(ThemeChoice choice) {
    switch (choice) {
      case ThemeChoice.system:
        return l10n.themeSystem;
      case ThemeChoice.light:
        return l10n.themeLight;
      case ThemeChoice.dark:
        return l10n.themeDark;
      case ThemeChoice.oled:
        return l10n.themeOled;
    }
  }

  ThemeChoice _current() =>
      themeChoiceOf(AdaptiveTheme.of(context).mode, oledDark);

  void _pick() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: RadioGroup<ThemeChoice>(
          groupValue: _current(),
          onChanged: (choice) async {
            if (choice == null) return;
            Navigator.pop(dialogContext);
            await applyThemeChoice(context, choice);
            if (mounted) setState(() {});
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
              for (final choice in ThemeChoice.values)
                RadioListTile<ThemeChoice>(
                  value: choice,
                  title: Text(_label(choice)),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingSmall),
      child: ListTile(
        leading: Icon(Icons.brightness_6_outlined,
            size: 28, color: cs.onSurfaceVariant),
        title: Text(l10n.themeTitle, style: tt.titleLarge),
        subtitle: Text(_label(_current()),
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        onTap: _pick,
      ),
    );
  }
}
