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

  testWidgets('the theme row opens a dialog; choosing Dark sets the mode',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(manager(tester).mode, AdaptiveThemeMode.system);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<AdaptiveThemeMode>), findsNWidgets(3));

    await tester
        .tap(find.widgetWithText(RadioListTile<AdaptiveThemeMode>, 'Dark'));
    await tester.pumpAndSettle();
    expect(manager(tester).mode, AdaptiveThemeMode.dark);
    // the dialog is closed and the row now shows the choice
    expect(find.byType(RadioListTile<AdaptiveThemeMode>), findsNothing);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('the OLED switch saves oled_dark and makes dark pure black',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(SwitchListTile, 'Pure black (OLED)');
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool('oled_dark'), true);
    expect(global.oledDark, isTrue);
    expect(
        manager(tester).darkTheme.colorScheme.surface, const Color(0xFF000000));

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool('oled_dark'), false);
    expect(
        manager(tester).darkTheme.colorScheme.surface, const Color(0xFF0C0B09));
  });
}
