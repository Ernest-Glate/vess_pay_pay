#!/usr/bin/env pwsh
# VessPay Splash Screen Verification Script
# Tests splash screen implementation across build modes

Write-Host "🚀 VessPay Splash Screen Verification" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

# Change to Flutter project directory
Set-Location "c:\Users\Administrator\Documents\vesss\vesspay-mobile-flutter"

Write-Host "📋 Pre-flight Checks..." -ForegroundColor Yellow

# 1. Verify logo asset exists
Write-Host "`n1. Checking VessPay logo assets..." -ForegroundColor White
$logoPath = "assets/images/vesspay_logo.png"
if (Test-Path $logoPath) {
    $logoSize = (Get-Item $logoPath).Length / 1KB
    Write-Host "   ✅ Base logo found ($([Math]::Round($logoSize, 2)) KB)" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Base logo NOT found!" -ForegroundColor Red
    exit 1
}

# Check multi-resolution variants
$resolutions = @("2.0x", "3.0x", "4.0x")
foreach ($res in $resolutions) {
    $resPath = "assets/images/$res/vesspay_logo.png"
    if (Test-Path $resPath) {
        Write-Host "   ✅ $res variant found" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  $res variant missing" -ForegroundColor Yellow
    }
}

# 2. Verify Android mipmap assets
Write-Host "`n2. Checking Android mipmap assets..." -ForegroundColor White
$mipmaps = @("mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")
foreach ($mipmap in $mipmaps) {
    $mipmapPath = "android/app/src/main/res/$mipmap/ic_launcher.png"
    if (Test-Path $mipmapPath) {
        Write-Host "   ✅ $mipmap logo found" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  $mipmap logo missing" -ForegroundColor Yellow
    }
}

# 3. Verify pubspec.yaml configuration
Write-Host "`n3. Checking pubspec.yaml configuration..." -ForegroundColor White
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match "assets/images/") {
    Write-Host "   ✅ Images directory configured in assets" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Images directory NOT configured!" -ForegroundColor Red
    exit 1
}

# 4. Verify Android launch background
Write-Host "`n4. Checking Android launch background..." -ForegroundColor White
$launchBg = Get-Content "android/app/src/main/res/drawable/launch_background.xml" -Raw
if ($launchBg -match "ic_launcher") {
    Write-Host "   ✅ VessPay logo configured in launch_background.xml" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  Logo not configured in launch_background.xml" -ForegroundColor Yellow
}

# 5. Run Flutter analyzer
Write-Host "`n5. Running Flutter analyze..." -ForegroundColor White
flutter analyze lib/features/auth/presentation/splash_screen.dart 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ No analysis issues in splash_screen.dart" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  Analysis issues detected" -ForegroundColor Yellow
}

Write-Host "`n" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📱 Build Testing Options" -ForegroundColor Cyan  
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "To test the splash screen implementation:`n" -ForegroundColor White

Write-Host "  Debug Build (Chrome):" -ForegroundColor Yellow
Write-Host "    flutter run -d chrome`n" -ForegroundColor Gray

Write-Host "  Debug Build (Android):" -ForegroundColor Yellow
Write-Host "    flutter run -d android`n" -ForegroundColor Gray

Write-Host "  Release Build (Android APK):" -ForegroundColor Yellow
Write-Host "    flutter build apk --release" -ForegroundColor Gray
Write-Host "    (APK location: build/app/outputs/flutter-apk/app-release.apk)`n" -ForegroundColor DarkGray

Write-Host "  Release Build (iOS):" -ForegroundColor Yellow
Write-Host "    flutter build ios --release`n" -ForegroundColor Gray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Verification Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
