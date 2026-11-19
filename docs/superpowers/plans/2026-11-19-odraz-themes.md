# odraz themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Warm whaling.xyz-style Light/Dark/OLED color schemes, a Theme setting (System default) with an OLED switch, then build and publish odraz 1.1.

**Architecture:** Extend `buildBrandColorScheme`/`resolveColorScheme` in `lib/theme.dart` with the new palette and an `oled` flag. Theme choice uses the existing `adaptive_theme` package (mode persisted by the package, initial mode read in `main()`); the OLED flag lives in `SharedPreferences` (`oled_dark`) and a global like `seedColor`. A small widget (`ThemeSettingsTiles`) in a new `lib/theme_settings.dart` is dropped into the settings list.

**Tech Stack:** Flutter 3.41.4 / Material 3, adaptive_theme 3.7.2, shared_preferences.

**Spec:** `docs/superpowers/specs/2026-11-19-odraz-themes-design.md`

## Global Constraints

- **Colors only:** no font, radius, elevation, border or layout changes.
- Palette per the spec table (Light / Dark / OLED), with accents `#4D96FF` (secondary) and `#4DDCFF` (tertiary) in all three.
- Default theme mode is **System**; mode choice is remembered between launches; OLED applies whenever dark is active (including System turning dark).
- Pref key for OLED: `oled_dark` (bool, default false). Existing `seed_color` still overrides the brand default, in light and dark.
- Wallpaper (Material You) colors stay unused. English-only strings. No iOS/macOS/Windows changes; the icon generator must not touch `ios/`.
- Version `1.1.0+21`; git tag `odraz-1.1.0`; release title "odraz 1.1"; upstream owns tag `v1.1.0`, do not use it.

## Review Focus

1. A saved theme mode must not be reset at launch: `main()` must pass the saved mode, and `MaterialApp` must not hard-code `themeMode: ThemeMode.light`. (Task 2)
2. First run with nothing saved resolves to System, not Light. (Task 2)
3. OLED applies in dark mode reached through System, not only through an explicit Dark choice, and toggling OLED at runtime updates the dark theme immediately. (Task 2)
4. Text pairs readable in all three schemes: onPrimary/onSecondary/onTertiary at least 4.5:1, onSurface at least 7:1, onSurfaceVariant at least 4.5:1. (Task 1)
5. A saved custom `seed_color` still wins in both light and dark (the old code updated only the light theme). (Tasks 1, 2)

---

### Task 1: Warm Light / Dark / OLED color schemes

**Files:**
- Modify: `lib/design_tokens.dart` (palette constants), `lib/theme.dart`
- Test: `test/unit/brand_theme_test.dart` (update)

**Interfaces:**
- Produces:
  - `ColorScheme buildBrandColorScheme(Brightness brightness, {bool oled = false})`
  - `ColorScheme resolveColorScheme({Color? userSeed, required Brightness brightness, bool oled = false})`: seed overrides primary colors; `oled` pins the OLED surface roles when `brightness == dark` (also with a custom seed).
  - `AppColors` constants for every value in the spec table (names are the builder's choice; keep `brandViolet`, `brandBlue`, `brandCyan` as they are).

- [ ] **Step 1: Update the tests first** in `test/unit/brand_theme_test.dart`:
  - `light scheme uses the warm palette`: `surface #FAF8F2`, `surfaceContainerLow #FDFCF7`, `surfaceContainer #F7F4ED`, `surfaceContainerHighest #EDE8DC`, `onSurface #0A0A0B`, `onSurfaceVariant #6B6457`, `outlineVariant #E8E3D8`, `primary #6B4FD8`, `secondary #4D96FF`, `tertiary #4DDCFF`.
  - `dark scheme uses the warm palette`: `surface #0C0B09`, `surfaceContainerLow #161512`, `surfaceContainer #1C1B17`, `surfaceContainerHighest #2B2A24`, `onSurface #EDEDEE`, `onSurfaceVariant #A0A0A6`, `outlineVariant #2A2924`, `primary #A78BFA`, `onPrimary #0B0817`, `secondary #4D96FF`, `tertiary #4DDCFF`.
  - `oled scheme is pure black`: `buildBrandColorScheme(dark, oled: true)` has `surface #000000`, `surfaceContainerLow #0A0A0A`, `surfaceContainer #121212`, `surfaceContainerHighest #222222`, `outlineVariant #242424`, and the same `primary`/`onSurface` as dark; `oled: true` with `Brightness.light` equals the light scheme.
  - `readable pairs` for light, dark and OLED (existing helper): onPrimary/primary, onSecondary/secondary, onTertiary/tertiary at least 4.5, onSurface/surface at least 7, onSurfaceVariant/surface at least 4.5.
  - `seed color overrides in both modes`: `resolveColorScheme(userSeed: X, brightness: light)` and `(dark)` both have `primary != brandViolet/#A78BFA`; `(userSeed: X, dark, oled: true).surface == #000000`.
  - keep `default seed color is the brand violet`.
- [ ] **Step 2: Run** `flutter test test/unit/brand_theme_test.dart`. Expected: FAIL (old palette, `oled` parameter missing).
- [ ] **Step 3: Implement** the palette constants and extend both functions per the Interfaces block. Start from `ColorScheme.fromSeed(seedColor: brandViolet, brightness: ...)` and `copyWith` every role named in the tests; pick `onSecondary`/`onTertiary` (ink `#111827` in light, `#0B0817` in dark) so contrast passes.
- [ ] **Step 4: Run** the test file, then `flutter analyze lib/theme.dart lib/design_tokens.dart` (no errors). Expected: PASS.
- [ ] **Step 5: Commit** — `feat(theme): warm light, dark and OLED color schemes`

### Task 2: Theme mode setting and OLED switch

**Files:**
- Create: `lib/theme_settings.dart`, `test/widgets/theme_settings_test.dart`
- Modify: `lib/main.dart` (pass saved mode, default System, OLED-aware dark theme, `themeMode`), `lib/global.dart` (`bool oledDark`, loaded from prefs next to `seed_color`), `lib/settings_route.dart` (insert `const ThemeSettingsTiles()` before the divider above "clear cache"), `lib/l10n/app_en.arb` (+ regenerate)

**Interfaces:**
- Consumes: `resolveColorScheme(..., oled:)` and `buildThemeData(colorScheme:, brightness:)` (existing in `lib/theme.dart`).
- Produces:
  - `AdaptiveThemeMode resolveInitialThemeMode(AdaptiveThemeMode? saved)` in `lib/theme_settings.dart`: `saved ?? AdaptiveThemeMode.system`.
  - `ThemeData buildDarkThemeData({Color? userSeed, required bool oled})`.
  - `Future<void> applyOledDark(BuildContext context, bool value)`: sets global `oledDark`, saves `oled_dark`, calls `AdaptiveTheme.of(context).setTheme(light: <current light>, dark: buildDarkThemeData(...))`.
  - `class ThemeSettingsTiles extends StatelessWidget`: a "Theme" tile showing the current mode that opens a dialog with three `RadioListTile`s (System, Light, Dark; picking one calls `AdaptiveTheme.of(context).setSystem/setLight/setDark`), and a `SwitchListTile` "Pure black (OLED)" bound to `oledDark`.
  - l10n keys: `themeTitle` "Theme", `themeSystem` "System", `themeLight` "Light", `themeDark` "Dark", `themeOled` "Pure black (OLED)", `themeOledDesc` "Saves battery on OLED screens. Applies in dark mode."

- [ ] **Step 1: Write the failing tests** in `test/widgets/theme_settings_test.dart` (mock prefs with `SharedPreferences.setMockInitialValues`; wrap `ThemeSettingsTiles` in `AdaptiveTheme(light:, dark:, initial: resolveInitialThemeMode(null), builder: ...MaterialApp...)` with the l10n delegates):
  - `resolveInitialThemeMode(null) == system`, `(dark) == dark`, `(light) == light`.
  - `theme row opens a dialog with System, Light and Dark; choosing Dark sets the mode`: tap "Theme", expect the three labels, tap "Dark", `AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark`; the tile subtitle then reads "Dark".
  - `OLED switch is off by default, toggling it saves oled_dark and makes the dark theme pure black`: tap the switch; `SharedPreferences.getInstance()` has `oled_dark == true`; `AdaptiveTheme.of(context).darkTheme.colorScheme.surface == Color(0xFF000000)`; toggling back restores `#0C0B09`.
  - `buildDarkThemeData(userSeed: null, oled: false/true)` surface equals `#0C0B09` / `#000000`.
- [ ] **Step 2: Run** `flutter test test/widgets/theme_settings_test.dart`. Expected: FAIL (compile errors).
- [ ] **Step 3: Implement** the Interfaces block, the l10n keys (add to `app_en.arb`, run `flutter gen-l10n`), and the `oledDark` global loaded in `Global.init` beside `seed_color`.
- [ ] **Step 4: Wire `main.dart`**: `main()` reads `await AdaptiveTheme.getThemeMode()` and passes it to `MyApp` (new field `initialThemeMode`); remove the `prefs.remove('adaptive_theme')` force-light block; build the dark theme with `buildDarkThemeData(userSeed: seedColor, oled: oledDark)`; `AdaptiveTheme(initial: resolveInitialThemeMode(initialThemeMode))`; delete `themeMode: ThemeMode.light` from `MaterialApp`. Replace the late `seed_color` `setTheme(light: ...)` block with one that updates both light (`resolveColorScheme`) and dark (`buildDarkThemeData`). Insert `const ThemeSettingsTiles()` in `settings_route.dart`.
- [ ] **Step 5: Verify wiring**: `grep -n "ThemeMode.light\|AdaptiveThemeMode.light\|prefs.remove('adaptive_theme')" lib/main.dart` shows none; `flutter analyze` on the touched files (no errors).
- [ ] **Step 6: Run** the new tests, then the full `flutter test` and compare the failing set with the 14 known failures (bg_task_scheduler 1, storage_test 3, onboarding_route 5, theme_consistency 3, two files that fail to load). If an onboarding or settings test newly fails because of the added tile, fix the cause. Expected: new tests PASS, failing set unchanged.
- [ ] **Step 7: Commit** — `feat(theme): theme mode setting (System default) and OLED switch`

### Task 3: Icon background, version 1.1 and release

**Files:**
- Modify: `tools/make_launcher_icons.py`, `tools/check_launcher_icons.py`, `pubspec.yaml` (`adaptive_icon_background`, `version`), generated Android resources, `README.md` (Download section mentions nothing version-specific; leave unless wrong)

- [ ] **Step 1: Update the check first**: `tools/check_launcher_icons.py` expects the legacy corner and background to be `#FAF8F2` (instead of `#F9FAFB`). Run it. Expected: FAIL.
- [ ] **Step 2: Update the generator**: separate the logo's own background (`LOGO_BG = #F9FAFB`, used only to cut the hexagon out) from the icon background (`ICON_BG = #FAF8F2`, used for the legacy canvas); regenerate both PNGs; the check passes. Set `adaptive_icon_background: "#FAF8F2"` in `pubspec.yaml` and run `dart run flutter_launcher_icons`; confirm `git status --short ios` is empty and `values/colors.xml` has `#FAF8F2`; revert any `pubspec.lock` change.
- [ ] **Step 3: Set** `version: 1.1.0+21` in `pubspec.yaml`.
- [ ] **Step 4: Build** `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./debug-info` (env: `JAVA_HOME` = `~/dev/jdk/jdk-17*`, `ANDROID_HOME=~/Android`). For each ABI APK, `aapt2 dump badging` shows package `xyz.whaling.odraz`, `versionName='1.1.0'`, a `versionCode` above the 0.1.0 build (2020 for arm64), label `odraz`. Copy them to `/tmp/rel/odraz-1.1.0-<abi>.apk` and write `SHA256SUMS.txt`.
- [ ] **Step 4b: Run** the checks once more on the final tree: `python3 -I tools/check_launcher_icons.py`, the new Flutter tests, `go build ./...`.
- [ ] **Step 5: Commit**, merge the branch into `master` (fast-forward), `git push origin master`, delete the merged branch.
- [ ] **Step 6: Publish**: `gh release create odraz-1.1.0 <3 APKs> SHA256SUMS.txt --repo 0xWailing/odraz --target master --latest --title "odraz 1.1"` with notes: what is new (warm light/dark/OLED themes, Theme setting with System default, OLED switch, cream launcher background), the install notes from the 0.1.0 release (which file for which phone, debug-signed, installs as `xyz.whaling.odraz` and upgrades 0.1.0 in place), and the honest known limits (S3 verified with Backblaze B2 and a local server, not AWS; dark screens only checked in tests; credentials stored unencrypted). Verify with `gh release view odraz-1.1.0 --repo 0xWailing/odraz`.
