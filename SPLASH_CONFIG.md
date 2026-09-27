# VessPay Native Splash Screen Configuration

This document outlines the native splash screen setup for VessPay across all platforms.

## Flutter Splash Screen

### Configuration
- **Logo Asset**: `assets/images/vesspay_logo.png`
- **Size**: 180x180 logical pixels
- **Quality**: High filter quality (`FilterQuality.high`)
- **Error Handling**: Graceful fallback to branded icon if logo fails to load
- **Animation**: Subtle pulse and shimmer for premium feel

### Multi-Resolution Support
Created asset variants for different screen densities:
- `assets/images/vesspay_logo.png` (1.0x - base)
- `assets/images/2.0x/vesspay_logo.png` (2.0x)
- `assets/images/3.0x/vesspay_logo.png` (3.0x)
- `assets/images/4.0x/vesspay_logo.png` (4.0x)

## Android Native Splash

### Files Modified
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`

### Custom Logo Setup
Place VessPay logo in Android mipmap folders for native splash:
- `android/app/src/main/res/mipmap-mdpi/` (48x48 dp)
- `android/app/src/main/res/mipmap-hdpi/` (72x72 dp)
- `android/app/src/main/res/mipmap-xhdpi/` (96x96 dp)
- `android/app/src/main/res/mipmap-xxhdpi/` (144x144 dp)
- `android/app/src/main/res/mipmap-xxxhdpi/` (192x192 dp)

## iOS Native Splash

### Files Modified
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`

### Assets Required
Add VessPay logo to iOS asset catalog:
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

## Testing Checklist

### Debug Build Testing
- [ ] Run `flutter run -d <device>` and verify logo appears
- [ ] Check console for any image loading errors
- [ ] Verify no animation artifacts or pixelation
- [ ] Test on various screen sizes (phone, tablet)

### Release Build Testing  
- [ ] Build APK: `flutter build apk --release`
- [ ] Build iOS: `flutter build ios --release`
- [ ] Install on physical device
- [ ] Verify native splash matches Flutter splash
- [ ] Check logo quality and centering

### Cross-Device Validation
- [ ] Android phones (various densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] Android tablets
- [ ] iOS phones (@1x, @2x, @3x)
- [ ] iOS tablets
- [ ] Web browsers (Chrome, Safari, Firefox)

## Image Quality Specifications

- **Format**: PNG with transparency
- **Color Mode**: RGBA
- **Recommended Size**: Minimum 512x512px source
- **Aspect Ratio**: 1:1 (square)
- **Background**: Transparent or matches splash background gradient
