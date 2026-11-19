# odraz themes: warm palette, theme setting, OLED — short design

Status: approved by the owner (2026-11-19). Size: small change. Supersedes the palette in
`2026-11-19-odraz-branding-design.md` (the launcher icon work there stands).

## Intent
Re-color the app after whaling.xyz (warm cream paper / warm near-black, soft violet accent), let the
user choose the theme in settings (default: follow the phone), and offer a pure-black OLED dark mode.

## Goals
- Light, Dark and OLED color schemes; odraz accents (blue #4D96FF, cyan #4DDCFF) kept in all of them.
- Settings: a "Theme" row (System / Light / Dark, default System, remembered) and a "Pure black
  (OLED)" switch that applies whenever dark is active (including System turning dark).
- Launcher icon adaptive background becomes the light cream.

## Non-goals / anti-goals
- **Colors only.** No font, radius, elevation, border or layout changes (owner decision). No Geist font.
- No iOS/macOS/Windows work. Gallery/video screens keep functional black and white.
- A saved custom `seed_color` still overrides the brand default.
- Wallpaper (Material You) colors stay unused.

## Palette (from whaling.xyz stylesheet + odraz brand)
| Role | Light | Dark | OLED |
|---|---|---|---|
| surface | #FAF8F2 | #0C0B09 | #000000 |
| surfaceContainerLow (cards) | #FDFCF7 | #161512 | #0A0A0A |
| surfaceContainer | #F7F4ED | #1C1B17 | #121212 |
| surfaceContainerHighest | #EDE8DC | #2B2A24 | #222222 |
| onSurface (text) | #0A0A0B | #EDEDEE | #EDEDEE |
| onSurfaceVariant (muted text) | #6B6457 | #A0A0A6 | #A0A0A6 |
| outlineVariant (hairlines) | #E8E3D8 | #2A2924 | #242424 |
| primary / onPrimary | #6B4FD8 / #FFFFFF | #A78BFA / #0B0817 | #A78BFA / #0B0817 |
| secondary (blue) / on | #4D96FF / #111827 | #4D96FF / #0B0817 | same as Dark |
| tertiary (cyan) / on | #4DDCFF / #111827 | #4DDCFF / #0B0817 | same as Dark |

## Approaches
- **OLED:** (A) a switch applying to dark mode (chosen); (B) a fourth option in the picker.
- **Mode handling:** use the existing `adaptive_theme` package (already wired in `main.dart`): read the
  saved mode at startup, default `AdaptiveThemeMode.system`; keep the OLED flag in
  `SharedPreferences` (`oled_dark`) and rebuild the dark `ThemeData` from it.

## Builder's calls
- Pairs must stay readable: onPrimary/onSecondary/onTertiary vs their color >= 4.5:1, onSurface vs
  surface >= 7:1, onSurfaceVariant vs surface >= 4.5:1, in all three schemes.
- Remaining roles (containers, outline) derive from `ColorScheme.fromSeed` unless set above.
- Version 1.1.0+21; tag `odraz-1.1.0` (upstream already owns `v1.1.0`); release title "odraz 1.1".
- Dark screens can't be eyeballed on a device here; hard-coded `Colors.white/black` in gallery/viewer
  stay as they are and are reported as known risk.

## Update (owner decision, after 1.1)
OLED is a **fourth choice in the Theme picker** (System / Light / Dark / OLED), not a switch on top of
Dark. OLED = dark mode with pure-black surfaces. System follows the phone and uses the regular dark
theme. The `oled_dark` preference stays, but only counts while dark is the chosen mode: a leftover
flag from 1.1 (switch on while on System) is dropped at startup.
