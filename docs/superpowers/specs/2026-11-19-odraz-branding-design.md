# odraz branding: launcher icon and UI colors — short design

Status: approved by the owner (2026-11-19). Size: small change.

## Intent
Make the app look like odraz: a bigger launcher icon on Android and UI colors taken from the new
logo instead of the inherited teal / wallpaper colors.

## Goals
- Launcher icon: hexagon fills the visible icon area on Android 8+ (adaptive icon) and on older
  phones (tight-cropped legacy icon).
- UI colors (icons, backgrounds, text, switches, buttons) follow the brand palette below.

## Non-goals / anti-goals
- No dark-mode switch: the app stays locked to light (owner decision). A dark brand scheme is built
  but not enabled.
- No iOS/macOS/Windows icon or theme work (not maintained).
- Must not break existing screens: gallery/video screens keep their functional black and white.
- A user-saved custom color (`seed_color` preference) still overrides the default.

## Palette (sampled from the logo)
| Role | Light (default) | Dark (built, not enabled) |
|---|---|---|
| background / surface | #F9FAFB | #180448 |
| text (onSurface) | #111827 | #F9FAFB |
| primary | #6B4FD8 violet | #4DDCFF cyan |
| secondary | #4D96FF blue | #6B4FD8 |
| accent (tertiary) | #4DDCFF cyan | #4D96FF |

## Approaches
- **Icon:** (A) adaptive icon with a transparent hexagon foreground on a #F9FAFB background layer,
  plus tight-cropped legacy icons (chosen); (B) only crop the existing PNG (Android 8+ still
  shrinks it into a tile, so it stays small); (C) use the cloud mark alone on a dark background
  (departs from the hexagon the owner named as the logo).
- **Colors:** (A) explicit brand ColorSchemes built from the palette, wallpaper (Material You) colors
  turned off (chosen); (B) only change the seed color (wallpaper colors would still win on most
  Android 12+ phones, so branding would not show).

## Builder's calls
- Foreground scaled so the hexagon height is about 61% of the adaptive layer (inside the 66/108
  safe zone); background color #F9FAFB.
- Start from `ColorScheme.fromSeed(seedColor: #6B4FD8)` and override the roles in the table.
- Update `seedThemeColors[0]` to the brand violet so the default seed matches.
- The hard-coded-color regression test whitelist must keep passing (new colors live in `theme.dart`).
