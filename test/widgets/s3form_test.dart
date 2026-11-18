import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:img_syncer/global.dart' as global;
import 'package:img_syncer/l10n/app_localizations.dart';
import 'package:img_syncer/storageform/s3form.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          global.initI18n(context);
          return const Scaffold(body: SingleChildScrollView(child: S3Form()));
        },
      ),
    );
  }

  testWidgets('S3Form shows every field and both switches', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    for (final label in [
      'Endpoint',
      'Region',
      'Bucket',
      'Access key',
      'Secret key',
      'Root prefix',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'field "$label"');
    }
    expect(find.text('Use HTTPS (TLS)'), findsOneWidget);
    expect(find.text('Path-style addressing'), findsOneWidget);
    expect(find.textContaining('must already exist'), findsOneWidget);
  });

  testWidgets('path-style follows the endpoint until the user toggles it',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    SwitchListTile pathStyle() => tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Path-style addressing'));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Endpoint'), 's3.amazonaws.com');
    await tester.pump();
    expect(pathStyle().value, isFalse);

    await tester.enterText(find.widgetWithText(TextFormField, 'Endpoint'),
        's3.us-west-004.backblazeb2.com');
    await tester.pump();
    expect(pathStyle().value, isTrue);
  });

  testWidgets('a manual path-style choice is not overridden by the endpoint',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    SwitchListTile pathStyle() => tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Path-style addressing'));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Endpoint'), 'localhost:9000');
    await tester.pump();
    expect(pathStyle().value, isTrue);

    await tester.ensureVisible(find.text('Path-style addressing'));
    await tester.tap(find.text('Path-style addressing'));
    await tester.pump();
    expect(pathStyle().value, isFalse);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Endpoint'), 's3.example.com');
    await tester.pump();
    expect(pathStyle().value, isFalse, reason: 'user choice must stick');
  });
}
