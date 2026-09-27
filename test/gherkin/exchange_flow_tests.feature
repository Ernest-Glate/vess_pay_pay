Feature: Currency Exchange Flow
  As a user
  I want to exchange currencies safely and efficiently
  So that I can manage my international finances

  Background:
    Given I am logged into the VessPay app
    And I am on the dashboard screen
    And I have sufficient balance in my GHS wallet

  # Happy Path Scenarios

  Scenario: Successful currency exchange from GHS to USD
    Given I have 12,450 GHS in my wallet
    When I tap the "Swap" quick action button
    Then I should see the Exchange screen with title "EXCHANGE"
    And the fee should display as "0.03" not "3%"
    When I select "GHS" as the source currency
    And I select "USD" as the destination currency
    And I enter "100" in the amount field
    Then I should see the exchange rate as "0.0810"
    And I should see I will receive approximately "8.10 USD"
    When I tap the "Confirm Exchange" button
    And I wait for the exchange to process
    Then I should see the "Exchange Confirmed & Successful" message
    And the transaction fee should show "0.03" in decimal format
    And the summary should show "100.00 GHS" exchanged
    And the summary should show "8.10 USD" received
    When I tap the "Done" button
    Then I should return to the dashboard
    And my GHS balance should be reduced by 100
    And my USD balance should be increased by approximately 8.10

  Scenario: Currency selector with search functionality
    When I tap the "Swap" quick action button
    And I tap the source currency selector
    Then I should see the "SELECT CURRENCY" bottom sheet
    And I should see all 5 supported currencies:
      | Currency | Code | Flag  |
      | Ghanaian Cedi | GHS | 🇬🇭 |
      | United States Dollar | USD | 🇺🇸 |
      | British Pound Sterling | GBP | 🇬🇧 |
      | Euro | EUR | 🇪🇺 |
      | Nigerian Naira | NGN | 🇳🇬 |
    When I type "uni" in the search field
    Then I should see only "United States Dollar (USD)"
    And I should not see "GHS", "GBP", "EUR", or "NGN"
    When I tap "United States Dollar"
    Then the currency selector should close
    And the source currency should be set to "USD"

  Scenario: Swap currencies using the swap button
    Given I am on the Exchange screen
    And the source currency is "GHS"
    And the destination currency is "USD"
    When I tap the swap button (swap icon)
    Then the source currency should become "USD"
    And the destination currency should become "GHS"
    And the swap animation should complete within 400ms

  # Error Handling Scenarios

  Scenario: Attempt to exchange with insufficient balance
    Given I have 100 GHS in my wallet
    When I tap the "Swap" quick action button
    And I enter "999999" in the amount field
    And I tap the "Confirm Exchange" button
    Then I should see the error message "Insufficient balance"
    And I should remain on the Exchange screen
    And the exchange should not be processed

  Scenario: Attempt to exchange without entering an amount
    When I tap the "Swap" quick action button
    And I leave the amount field empty
    And I tap the "Confirm Exchange" button
    Then I should see the error message "Please enter a valid amount"
    And I should remain on the Exchange screen

  Scenario: Attempt to exchange with invalid amount (negative)
    When I tap the "Swap" quick action button
    And I enter "-100" in the amount field
    And I tap the "Confirm Exchange" button
    Then I should see the error message "Please enter a valid amount"
    And the exchange should not be processed

  Scenario: Attempt to exchange with invalid amount (zero)
    When I tap the "Swap" quick action button
    And I enter "0" in the amount field
    And I tap the "Confirm Exchange" button
    Then I should see the error message "Please enter a valid amount"
    And the exchange should not be processed

  # Navigation Scenarios

  Scenario: Navigate back to dashboard using back arrow
    When I tap the "Swap" quick action button
    Then I should see the Exchange screen
    When I tap the back arrow button
    Then I should navigate to the dashboard screen
    And I should NOT see a blank white screen
    And I should NOT see a "bad state: no elements" error

  Scenario: Return to dashboard after successful exchange
    Given I have completed a successful exchange
    And I am on the Exchange Success screen
    When I tap the "Done" button
    Then I should navigate to the dashboard screen
    And my wallet balances should be updated
    And the dashboard should load without errors

  # Edge Cases

  Scenario: Exchange with very small amount
    When I tap the "Swap" quick action button
    And I enter "0.01" in the amount field
    And I tap the "Confirm Exchange" button
    Then the exchange should process successfully
    And the fee should still show as "0.03" decimal format

  Scenario: Exchange during slow network conditions
    Given the network is simulated to be slow (3G)
    When I tap the "Swap" quick action button
    And I enter "100" in the amount field
    And I tap the "Confirm Exchange" button
    Then I should see a loading indicator
    And the exchange should eventually complete or show a timeout error
    And I should NOT see a blank screen or crash

  Scenario: Currency selector empty search results
    When I tap the "Swap" quick action button
    And I tap the source currency selector
    And I type "xyz123" in the search field
    Then I should see the "No currencies found" message
    And I should see the empty state icon
    And I should see the message "Try searching with a different term"

  # Accessibility Scenarios

  Scenario: Currency selector with keyboard navigation
    Given I am using keyboard navigation
    When I tap the "Swap" quick action button
    And I tap the source currency selector
    And I press Tab to focus the search field
    And I press Arrow Down to move to the first currency
    And I press Arrow Down again to move to the next currency
    And I press Enter to select the currency
    Then the selected currency should be applied
    And the currency selector should close

  Scenario: Screen reader announces currency selection
    Given I have enabled VoiceOver/TalkBack
    When I tap the "Swap" quick action button
    And I tap the source currency selector
    And I navigate to "United States Dollar"
    Then the screen reader should announce "Select United States Dollar, USD"
    When the currency is selected
    Then the screen reader should announce the selected currency

  # Fee Display Verification (Critical)

  Scenario Outline: Fee always displays as decimal 0.03 not percentage 3%
    When I am on the <screen>
    Then the transaction fee should display as "0.03"
    And the transaction fee should NOT display as "3 %"
    And the transaction fee should NOT display as "3%"

    Examples:
      | screen |
      | Exchange screen |
      | Exchange Success screen |
      | Transaction confirmation modal |

  # Performance Scenarios

  Scenario: Exchange screen loads smoothly
    When I navigate to the Exchange screen
    Then the screen should load within 1 second
    And the frame rate should be 60 FPS during scrolling
    And the Cumulative Layout Shift should be less than 0.1

  Scenario: Currency selector animation performance
    When I tap the currency selector
    Then the bottom sheet should slide up within 300ms
    And the animation should be smooth with no jank
    When I select a currency
    Then the selection animation should complete within 200ms
    And I should feel haptic feedback (light impact)

  # Regression Prevention

  Scenario: No blank screen after back navigation
    When I navigate to Exchange screen
    And I tap the back arrow
    Then I should NOT see a blank white screen
    And I should NOT see any error screen
    And I should see the dashboard
    When I refresh the page
    Then I should NOT see a "bad state: no elements" error
    And the dashboard should load normally

  Scenario: No crash after verification completion
    Given I have just completed KYC verification
    When I tap "Get Started" immediately
    Then the dashboard should show skeleton loaders while loading
    And the dashboard should eventually load successfully
    And I should NOT see a "bad state: no elements" error

  # Cross-Device Scenarios

  Scenario Outline: Exchange works on different screen sizes
    Given I am using a device with <width>px width
    When I navigate to the Exchange screen
    Then all UI elements should be visible and accessible
    And the layout should follow the 8-pt grid system
    And no text should be truncated
    And all buttons should be tappable

    Examples:
      | width |
      | 320   | # iPhone SE
      | 375   | # iPhone 12
      | 768   | # iPad
      | 1024  | # Desktop
      | 1440  | # Large Desktop

  Scenario: Dark and light mode compatibility
    When I switch to <theme> mode
    Then the Exchange screen should render correctly
    And the currency selector should use the appropriate theme colors
    And text should have sufficient contrast (WCAG 2.2 AA)

    Examples:
      | theme |
      | dark  |
      | light |
