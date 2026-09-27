import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/static_landing_pages.dart';
import '../../features/auth/presentation/mfa_screen.dart';
import '../../features/auth/presentation/claim_profile_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wallet/presentation/transactions_screen.dart';
import '../../features/wallet/presentation/transaction_history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/account_settings_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../shared/widgets/main_layout.dart';
import '../../features/payments/presentation/add_money_screen.dart';
import '../../features/payments/presentation/send_money_screen.dart';
import '../../features/payments/presentation/confirm_payment_screen.dart';
import '../../features/payments/presentation/request_money_screen.dart';
import '../../features/payments/presentation/payment_success_screen.dart';
import '../../features/payments/presentation/pay_momo_screen.dart';
import '../../features/payments/presentation/exchange_success_screen.dart';
import '../../features/payments/presentation/currency_exchange_screen.dart';
import '../../features/payments/presentation/transaction_details_screen.dart';
import '../../features/profile/presentation/bank_accounts_screen.dart';
import '../../features/profile/presentation/change_pin_screen.dart';
import '../../features/scan/presentation/qr_scan_screen.dart';
import '../../shared/widgets/error_screen.dart';
import '../../features/payments/presentation/transaction_receipt_screen.dart';
import '../../features/payments/presentation/beneficiaries_screen.dart';
import '../../features/wallet/presentation/transaction_search_screen.dart';
import '../../features/analytics/presentation/spending_analytics_screen.dart';
import '../../features/payments/presentation/bill_payment_screen.dart';
import '../../features/payments/presentation/scheduled_payments_screen.dart';
import '../../features/settings/presentation/transaction_limits_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/models/transaction_model.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  // NOTE: Do NOT use ref.watch(authProvider) here — that would recreate the
  // entire GoRouter on every auth state change, resetting navigation to /splash.
  // Instead we use ref.read for the initial state and _AuthStateListenable
  // (via refreshListenable) to trigger redirect re-evaluation only.

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthStateListenable(ref),

    // Error handling to prevent blank screens and crashes
    errorBuilder: (context, state) {
      debugPrint('🔴 Navigation Error: ${state.error}');
      debugPrint('📍 Location: ${state.matchedLocation}');

      return ErrorScreen(
        error: state.error?.toString() ?? 'Unknown navigation error',
      );
    },
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isAuthScreen = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/landing' ||
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/verify-email' ||
                          state.matchedLocation == '/forgot-password' ||
                          state.matchedLocation == '/reset-password' ||
                          state.matchedLocation == '/onboarding' ||
                          state.matchedLocation == '/claim';

      // Always allow splash screen
      if (isSplash) return null;

      // Read current auth state (not watch — we're inside redirect, not build)
      final isLoggedIn = ref.read(authProvider).isAuthenticated;

      // Protect authenticated routes
      if (!isLoggedIn && !isAuthScreen) {
        return '/landing';
      }

      // Redirect logged in users away from auth screens
      if (isLoggedIn && isAuthScreen) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: '/landing',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const LandingScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const VerifyEmailScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const AboutScreen()),
      ),
      GoRoute(
        path: '/features',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const FeaturesScreen()),
      ),
      GoRoute(
        path: '/security',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SecurityInfoScreen()),
      ),
      GoRoute(
        path: '/payment-success',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return _buildPageWithTransition(
            context,
            state,
            PaymentSuccessScreen(
              amount: extra?['amount'],
              recipient: extra?['recipient'],
              transactionId: extra?['transactionId'],
              type: extra?['type'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/exchange-success',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          
          if (extra == null) {
            return _buildPageWithTransition(
              context,
              state,
              const ErrorScreen(error: 'Missing exchange transaction data'),
            );
          }
          
          return _buildPageWithTransition(
            context,
            state,
            ExchangeSuccessScreen(
              fromCurrency: extra['fromCurrency'] ?? 'GHS',
              toCurrency: extra['toCurrency'] ?? 'USD',
              fromAmount: extra['fromAmount'] ?? 0.0,
              toAmount: extra['toAmount'] ?? 0.0,
              rate: extra['rate'] ?? 1.0,
              timestamp: extra['timestamp'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/claim',
        pageBuilder: (context, state) {
          // Extract phone and token from deep-link query params
          final phone = state.uri.queryParameters['phone'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';

          if (phone.isEmpty || token.isEmpty) {
            return _buildPageWithTransition(
              context,
              state,
              const ErrorScreen(error: 'Invalid claim link. Missing phone or token.'),
            );
          }

          return _buildPageWithTransition(
            context,
            state,
            ClaimProfileScreen(phone: phone, claimToken: token),
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const LoginScreen()),
      ),
      
      // Main App Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Sub-screens (Non-shell) - each route defined exactly once
      GoRoute(
        path: '/mfa',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MfaScreen(),
      ),
      GoRoute(
        path: '/transactions',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const TransactionsScreen()),
      ),
      GoRoute(
        path: '/transaction-history',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const TransactionHistoryScreen()),
      ),
      GoRoute(
        path: '/add-money',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const AddMoneyScreen()),
      ),
      GoRoute(
        path: '/send-money',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SendMoneyScreen()),
      ),
      GoRoute(
        path: '/confirm-payment',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return _buildPageWithTransition(
            context,
            state,
            ConfirmPaymentScreen(
              amount: extra?['amount'] ?? '0.00',
              recipient: extra?['recipient'] ?? 'Unknown',
              phone: extra?['phone'],
              note: extra?['note'],
              network: extra?['network'],
              fee: extra?['fee'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/request-money',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const RequestMoneyScreen()),
      ),
      GoRoute(
        path: '/account-settings',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const AccountSettingsScreen()),
      ),
      GoRoute(
        path: '/pay-momo',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const PayMoMoScreen()),
      ),
      GoRoute(
        path: '/transaction-details',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const TransactionDetailsScreen()),
      ),
      GoRoute(
        path: '/bank-accounts',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const BankAccountsScreen()),
      ),
      GoRoute(
        path: '/change-pin',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ChangePinScreen()),
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const QRScanScreen()),
      ),
      // Premium Features Routes
      GoRoute(
        path: '/transaction-receipt/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final transaction = state.extra as TransactionModel?;
          
          if (transaction == null) {
            return _buildPageWithTransition(
              context,
              state,
              const ErrorScreen(error: 'Transaction not found'),
            );
          }
          
          return _buildPageWithTransition(
            context,
            state,
            TransactionReceiptScreen(transaction: transaction),
          );
        },
      ),
      GoRoute(
        path: '/beneficiaries',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const BeneficiariesScreen()),
      ),
      GoRoute(
        path: '/transaction-search',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const TransactionSearchScreen()),
      ),
      GoRoute(
        path: '/spending-analytics',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SpendingAnalyticsScreen()),
      ),
      GoRoute(
        path: '/bill-payment',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const BillPaymentScreen()),
      ),
      GoRoute(
        path: '/scheduled-payments',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ScheduledPaymentsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/transaction-limits',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const TransactionLimitsScreen()),
      ),
      GoRoute(
        path: '/fx-convert',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(context, state, const CurrencyExchangeScreen()),
      ),
    ],
  );
});

// Helper function to create smooth page transitions
Page<dynamic> _buildPageWithTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Bridges Riverpod auth state → GoRouter refreshListenable.
/// When auth changes (login/logout/register), GoRouter re-evaluates redirects.
class _AuthStateListenable extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _subscription;

  _AuthStateListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(authProvider, (_, __) {
      // Guard against notifying after disposal (can happen during hot-reload
      // or when the provider scope is torn down before the router)
      if (!_disposed) notifyListeners();
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _subscription.close();
    super.dispose();
  }
}
