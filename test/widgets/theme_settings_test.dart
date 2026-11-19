import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:img_syncer/global.dart' as global;
import 'package:img_syncer/l10n/app_localizations.dart';
import 'package:img_syncer/theme.dart';
import 'package:img_syncer/theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget harness() {
  return AdaptiveTheme(
    light: buildThemeData(
      colorScheme: resolveColorScheme(brightness: Brightness.light),
      brightness: Brightness.light,
    ),
    dark: buildDarkThemeData(userSeed: null, oled: false),
    initial: resolveInitialThemeMode(null),
    builder: (theme, darkTheme) => MaterialApp(
      theme: theme,
      darkTheme: darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: Builder(builder: (context) {
        global.initI18n(context);
        return Scaffold(body: ListView(children: const [ThemeSettingsTiles()]));
      }),
    ),
  );
}

AdaptiveThemeManager<ThemeData> manager(WidgetTester tester) =>
    AdaptiveTheme.of(tester.element(find.byType(ThemeSettingsTiles)));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // adaptive_theme saves the mode through the async preferences API.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    global.oledDark = false;
  });

  group('resolveInitialThemeMode', () {
    test('defaults to system when nothing is saved', () {
      expect(resolveInitialThemeMode(null), AdaptiveThemeMode.system);
    });
    test('keeps a saved mode', () {
      expect(resolveInitialThemeMode(AdaptiveThemeMode.dark),
          AdaptiveThemeMode.dark);
      expect(resolveInitialThemeMode(AdaptiveThemeMode.light),
          AdaptiveThemeMode.light);
    });
  });

  test('buildDarkThemeData is warm black, or pure black with oled', () {
    expect(buildDarkThemeData(userSeed: null, oled: false).colorScheme.surface,
        const Color(0xFF0C0B09));
    expect(buildDarkThemeData(userSeed: null, oled: true).colorScheme.surface,
        const Color(0xFF000000));
  });

  group('theme choice mapping', () {
    test('mode and oled flag map to one of four choices', () {
      expect(
          themeChoiceOf(AdaptiveThemeMode.system, false), ThemeChoice.system);
      expect(themeChoiceOf(AdaptiveThemeMode.light, false), ThemeChoice.light);
      expect(themeChoiceOf(AdaptiveThemeMode.dark, false), ThemeChoice.dark);
      expect(themeChoiceOf(AdaptiveThemeMode.dark, true), ThemeChoice.oled);
    });

    test('OLED only counts when dark is the chosen mode', () {
      expect(
          resolveOledFlag(savedOled: true, savedMode: AdaptiveThemeMode.dark),
          isTrue);
      expect(
          resolveOledFlag(savedOled: true, savedMode: AdaptiveThemeMode.system),
          isFalse);
      expect(resolveOledFlag(savedOled: true, savedMode: null), isFalse);
      expect(
          resolveOledFlag(savedOled: true, savedMode: AdaptiveThemeMode.light),
          isFalse);
      expect(
          resolveOledFlag(savedOled: false, savedMode: AdaptiveThemeMode.dark),
          isFalse);
    });
  });

  testWidgets('the theme row offers four choices and no separate switch',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('System'), findsOneWidget); // the row's current value

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<ThemeChoice>), findsNWidgets(4));
    for (final label in ['System', 'Light', 'Dark', 'OLED (pure black)']) {
      expect(find.widgetWithText(RadioListTile<ThemeChoice>, label),
          findsOneWidget,
          reason: label);
    }
  });

  testWidgets('choosing Dark sets dark mode with the warm black theme',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(RadioListTile<ThemeChoice>, 'Dark'));
    await tester.pumpAndSettle();

    expect(manager(tester).mode, AdaptiveThemeMode.dark);
    expect(global.oledDark, isFalse);
    expect(
        manager(tester).darkTheme.colorScheme.surface, const Color(0xFF0C0B09));
    expect(find.byType(RadioListTile<ThemeChoice>), findsNothing);
    expect(find.text('Dark'), findsOneWidget); // the row shows the choice
  });

  testWidgets('choosing OLED sets dark mode with pure black, and it sticks',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
        find.widgetWithText(RadioListTile<ThemeChoice>, 'OLED (pure black)'));
    await tester.pumpAndSettle();

    expect(manager(tester).mode, AdaptiveThemeMode.dark);
    expect(global.oledDark, isTrue);
    expect((await SharedPreferences.getInstance()).getBool('oled_dark'), true);
    expect(
        manager(tester).darkTheme.colorScheme.surface, const Color(0xFF000000));
    expect(find.text('OLED (pure black)'), findsOneWidget); // the row

    // leaving OLED turns the flag off again
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(RadioListTile<ThemeChoice>, 'Light'));
    await tester.pumpAndSettle();
    expect(manager(tester).mode, AdaptiveThemeMode.light);
    expect(global.oledDark, isFalse);
    expect((await SharedPreferences.getInstance()).getBool('oled_dark'), false);
    expect(
        manager(tester).darkTheme.colorScheme.surface, const Color(0xFF0C0B09));
  });
}
