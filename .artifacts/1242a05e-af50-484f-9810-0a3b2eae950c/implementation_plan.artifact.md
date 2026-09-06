# Fix "No Directionality widget found" error

The error occurs because `OfflineBannerWrapper` (which uses a `Scaffold`) is placed outside of `MaterialApp` in the widget tree. `MaterialApp` is responsible for providing the `Directionality` widget, which `Scaffold` (and many other widgets) requires.

## Proposed Changes

### Core UI Logic

#### [MODIFY] [main.dart](file:///D:/Work_Hub/Flutter/TradingPro/lib/main.dart)
Move `OfflineBannerWrapper` inside the `builder` property of `MaterialApp.router`. This ensures it has access to the `Directionality` and `Theme` provided by `MaterialApp`.

#### [MODIFY] [main_admin.dart](file:///D:/Work_Hub/Flutter/TradingPro/lib/main_admin.dart)
Similarly, move `OfflineBannerWrapper` inside the `builder` property of `MaterialApp.router` in the admin app.

#### [MODIFY] [connectivity_service.dart](file:///D:/Work_Hub/Flutter/TradingPro/lib/services/connectivity_service.dart)
(Optional but recommended) Consider if `OfflineBannerWrapper` should return a `Scaffold`. If it's used inside `MaterialApp.builder`, it wraps the entire navigation stack. Using a `Material` or `Overlay` might be more appropriate if we want to avoid nested Scaffolds, but moving it inside `MaterialApp` is the primary fix for the `Directionality` error. I will keep the `Scaffold` for now as it's the simplest change, but move it inside the `MaterialApp` context.

## Verification Plan

### Manual Verification
- Run the app and verify the red error screen no longer appears after the splash screen.
- Toggle airplane mode or disable internet to verify the offline banner still appears correctly.
