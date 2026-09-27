# Logo Display Instructions

The VessPay logo is not displaying because **hot reload doesn't pick up new asset changes**.

## Quick Fix (Do this now):

1. **Stop the current Flutter app** (press `q` in the terminal or close the browser)
2. **Restart the app:**
   ```bash
   cd vesspay-mobile-flutter
   flutter run -d chrome
   ```

## Why This Happens

Flutter caches assets during the initial build. When you add new images after the app is already running:
- Hot reload (`r`) = Does NOT reload new assets ❌
- Hot restart (`R`) = Does NOT reload new assets ❌  
- Full app restart = Loads new assets ✅

## Verification

After restarting, you should see:
- ✅ VessPay logo on splash screen (not the wallet fallback icon)
- ✅ Logo displays with pulse and shimmer animation
- ✅ Smooth transition to landing page

The logo file exists at:
- `assets/images/vesspay_logo.png` (379 KB)
- Multi-resolution variants in `2.0x`, `3.0x`, and `4.0x` folders

## If Logo Still Doesn't Show

Run these commands:
```bash
cd vesspay-mobile-flutter
flutter clean
flutter pub get
flutter run -d chrome
```

This will force a complete rebuild and reload all assets.
