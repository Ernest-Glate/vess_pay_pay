# Manual QA Testing Guide - Exchange Screen

## Prerequisites
- Flutter app running on `flutter run -d chrome` (for web testing)
- For mobile: `flutter run` on connected device
- Test data: Demo account with sufficient balance (12,450 GHS)

---

## Test Case 1: Happy Path - Complete Exchange Flow

**Objective**: Verify full exchange flow from dashboard to success

### Steps:
1. Navigate to dashboard
2. Tap "Swap" quick action button
3. Verify you're on the Exchange screen (title says "EXCHANGE")
4. Check initial state:
   - ✅ Fee displays as "**0.03**" NOT "3%"
   - ✅ Currency selectors show flag emojis (e.g., 🇬🇭 GHS)
   - ✅ Rate is displayed
5. Enter amount "100" in the "You Send" field
6. Verify calculated "You Receive" amount appears
7. Tap "Confirm Exchange" button
8. Wait for processing (~1 second)
9. Verify navigation to success screen
10. Check success screen shows:
    - ✅ "Exchange Confirmed & Successful" message
    - ✅ Correct amounts (100 GHS sent, ~8.10 USD received)
    - ✅ Fee displayed as "**0.03**" (decimal format)
    - ✅ Exchange rate shown
    - ✅ Timestamp displayed
11. Tap "Done" button
12. Verify return to dashboard
13. Check wallet balances updated correctly

**Expected Result**: ✅ All steps complete without errors

---

## Test Case 2: Navigation - Back Button

**Objective**: Verify back button navigates to dashboard without crashes

### Steps:
1. Navigate to Exchange screen
2. Tap back arrow (top-left)
3. Verify immediate navigation to dashboard
4. Check for errors in console
5. Refresh page
6. Verify dashboard loads normally

**Expected Result**: 
- ✅ No blank white screen
- ✅ No "bad state: no elements" error
- ✅ Smooth return to dashboard

---

## Test Case 3: Currency Selector - Search Functionality

**Objective**: Verify currency selector search and selection

### Steps:
1. Navigate to Exchange screen
2. Tap the "You Send" currency selector (shows current currency + dropdown icon)
3. Verify bottom sheet opens with:
   - ✅ "SELECT CURRENCY" header
   - ✅ Search field at top
   - ✅ All 5 currencies listed with flags:
     - 🇬🇭 GHS - Ghanaian Cedi
     - 🇺🇸 USD - United States Dollar
     - 🇬🇧 GBP - British Pound Sterling
     - 🇪🇺 EUR - Euro
     - 🇳🇬 NGN - Nigerian Naira
4. Type "uni" in search field
5. Verify only USD appears
6. Clear search, type "euro"
7. Verify only EUR appears
8. Type "xyz123" (invalid)
9. Verify "No currencies found" empty state
10. Clear search
11. Tap "United States Dollar"
12. Verify selector closes and USD is now selected

**Expected Result**: ✅ Search filters correctly, selection works

---

## Test Case 4: Currency Swap

**Objective**: Verify swap button functionality

### Steps:
1. On Exchange screen, note current currencies (e.g., GHS → USD)
2. Tap the swap icon (circular button between currency inputs)
3. Verify swap animation plays (~400ms)
4. Verify currencies reversed (USD → GHS)
5. Check amounts recalculate correctly

**Expected Result**: ✅ Currencies swap with smooth animation

---

## Test Case 5: Error - Insufficient Balance

**Objective**: Verify insufficient balance handling

### Steps:
1. On Exchange screen
2. Enter amount "999999" (exceeds balance)
3. Tap "Confirm Exchange"
4. Verify error snackbar appears: "Insufficient balance"
5. Verify still on Exchange screen (no navigation)
6. Verify no wallet changes

**Expected Result**: ✅ Error message shown, exchange prevented

---

## Test Case 6: Error - Invalid Amount

**Objective**: Verify invalid input handling

### Steps:
Test 6a - Empty Amount:
1. Leave amount field empty
2. Tap "Confirm Exchange"
3. Verify error: "Please enter a valid amount"

Test 6b - Zero Amount:
1. Enter "0"
2. Tap "Confirm Exchange"
3. Verify error: "Please enter a valid amount"

Test 6c - Negative Amount:
1. Enter "-100"
2. Tap "Confirm Exchange"
3. Verify error: "Please enter a valid amount"

**Expected Result**: ✅ All invalid inputs blocked with clear errors

---

## Test Case 7: Visual Consistency Audit

**Objective**: Verify pixel-perfect UI quality

### Elements to Check:
- ✅ All spacing follows 8-pt grid (8, 12, 16, 20, 24, 32, 40px)
- ✅ Font weights consistent (bold for headers)
- ✅ Colors use AppColors theme (no hard-coded hex values)
- ✅ Icons properly aligned
- ✅ No visual glitches or cutoff text
- ✅ Glass morphism effects render correctly
- ✅ Shadows and gradients smooth

**Expected Result**: ✅ Professional, polished appearance

---

## Test Case 8: Accessibility Testing

**Objective**: Verify screen reader support

### Prerequisites:
- Enable TalkBack (Android) or VoiceOver (iOS)

### Elements to Test:
1. Back button announces: "Navigate back to dashboard"
2. Swap button announces: "Swap currencies"
3. Confirm button announces: "Confirm exchange transaction"
4. Currency selectors are focusable and announce currency names
5. Tab navigation works logically (search → currencies → buttons)

**Expected Result**: ✅ All interactive elements accessible

---

## Test Case 9: Cross-Device Testing

**Objective**: Verify responsive design across devices

### Viewports to Test:
- 📱 **320px** (iPhone SE) - check no horizontal scroll
- 📱 **375px** (iPhone 12) - verify all elements visible
- 📱 **425px** (Android) - test touch targets ≥44px
- 📱 **768px** (iPad Portrait) - check layout adapts
- 💻 **1024px** (iPad Landscape) - verify card scaling
- 💻 **1440px** (Desktop) - ensure no excessive stretching

**Expected Result**: ✅ Perfect layout at all sizes

---

## Test Case 10: Performance Validation

**Objective**: Verify smooth performance

### Metrics to Check:
1. **Frame Rate**: 
   - Open Chrome DevTools → Performance
   - Record while scrolling and interacting
   - Verify consistently ≥60 FPS
   
2. **Cumulative Layout Shift (CLS)**:
   - Run Lighthouse audit
   - Target: CLS < 0.1
   
3. **Animation Performance**:
   - Currency swap animation smooth
   - Currency selector slide-up smooth
   - No jank or stuttering

4. **Load Time**:
   - Exchange screen loads < 1 second
   - Currency selector opens < 300ms

**Expected Result**: ✅ All performance targets met

---

## Test Case 11: Fee Display Regression Prevention

**Objective**: Ensure fee ALWAYS shows as 0.03 decimal

### Screens to Check:
1. ✅ Exchange screen - "Fee: 0.03"
2. ✅ Exchange Success screen - "0.03 (₵3.00)" format
3. ❌ Should NEVER see "3%" or "3 %"

**Expected Result**: ✅ Decimal format everywhere

---

## Test Case 12: Edge Cases

**Objective**: Test unusual scenarios

### Test 12a - Very Small Amount:
1. Enter "0.01"
2. Verify exchange processes
3. Check fee still accurate

### Test 12b - Large Amount:
1. Enter "10000"
2. Verify formatting (commas if applicable)
3. Check calculations accurate

### Test 12c - Decimal Precision:
1. Enter "123.456789"
2. Verify rounding to 2 decimal places
3. Check calculated amount

**Expected Result**: ✅ All edge cases handled gracefully

---

## Defect Reporting Template

If you find any issues, report using this format:

```
**Title**: [Brief description]
**Severity**: Critical / High / Medium / Low
**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**: 
**Actual Result**: 
**Screenshots**: [Attach if applicable]
**Environment**: 
- Device: [e.g., iPhone 14 Pro]
- OS Version: [e.g., iOS 17.2]
- Browser: [e.g., Chrome 120]
- Screen Size: [e.g., 375x812]
```

---

## Sign-Off Checklist

Before approving for production:

- [ ] All 12 test cases passed
- [ ] No P0/P1 bugs remaining
- [ ] Accessible with screen readers
- [ ] Performs at 60fps
- [ ] Works on all target devices
- [ ] Fee displays correctly (0.03 decimal)
- [ ] No navigation crashes
- [ ] All error states handled gracefully

**QA Engineer**: ________________  
**Date**: ________________  
**Signature**: ________________  

---

## Additional Notes

**Browser Compatibility** (if testing web):
- ✅ Chrome (latest 3 versions)
- ✅ Firefox (latest 3 versions)
- ✅ Edge (latest 3 versions)
- ✅ Safari (latest 2 versions)

**Mobile OS Coverage**:
- ✅ iOS 15+ (iPhone SE, 12, 14 Pro)
- ✅ Android 10+ (Pixel, Samsung Galaxy)

**Regression Testing**:
- Retest after any code changes
- Verify CHANGELOG.md entries match actual changes
- Run `flutter test` before manual QA
