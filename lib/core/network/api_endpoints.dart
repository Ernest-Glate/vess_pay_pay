/// All VessPay backend API endpoint constants.
/// Maps to route mounts in vess-backend/src/server.ts.
class ApiEndpoints {
  ApiEndpoints._();

  // ── AUTH (mounted: ${apiPrefix}/auth → auth.routes.ts) ────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';
  static const String claimProfile = '/auth/claim';

  // ── USER PROFILE (mounted: ${apiPrefix}/auth → user.routes.ts) ────────────
  static const String getMe = '/auth/me';
  static const String updateMe = '/auth/me';

  // ── KYC (mounted: ${apiPrefix}/kyc → kyc.routes.ts) ───────────────────────
  static const String submitKyc = '/kyc';
  static const String getKycStatus = '/kyc/status';

  // ── WALLETS (mounted: ${apiPrefix}/wallets → wallet.routes.ts) ────────────
  //    GET /wallets/ → returns array of wallet objects with balance
  //    GET /transactions → mounted at ${apiPrefix} root
  static const String getBalance = '/wallets';
  static const String getTransactions = '/transactions';
  static String getTransactionById(String id) => '/wallets/transactions/$id';

  // ── FUNDING (mounted: ${apiPrefix}/funding → funding.routes.ts) ───────────
  static const String initiateLoad = '/funding/initiate';
  static const String confirmLoad = '/funding/confirm';
  static const String loadHistory = '/funding/history';

  // ── FX RATES (mounted: ${apiPrefix}/fx → fx.routes.ts) ────────────────────
  static const String getFxRates = '/fx/rates';
  static const String calculateFx = '/fx/calculate';
  static const String executeFx = '/fx/execute';
  static const String supportedCurrencies = '/fx/supported-currencies';

  // ── TRANSFERS (mounted: ${apiPrefix}/transfers → transfer.routes.ts) ──────
  static const String sendPayment = '/transfers/send';
  static const String requestPayment = '/transfers/request';
  static String getTransfer(String id) => '/transfers/$id';
  static String retryTransfer(String id) => '/transfers/$id/retry';

  // ── PAYMENTS (mounted: ${apiPrefix}/payments → payment.routes.ts) ─────────
  static const String paymentHistory = '/payments';
  static String getPayment(String id) => '/payments/$id';
  static String cancelPayment(String id) => '/payments/$id/cancel';

  // ── PAYMENT LIMITS (mounted: ${apiPrefix}/payment → payment-limits) ───────
  static const String getLimits = '/payment/limits';

  // ── MOMO (mounted: ${apiPrefix}/payments/momo → momo-payment.routes.ts) ───
  static const String momoInitiate = '/payments/momo/initiate';
  static String momoStatus(String id) => '/payments/momo/$id/status';
  static const String momoNetworks = '/payments/momo/networks';
  static String momoValidate(String phone) => '/payments/momo/validate/$phone';

  // ── FLUTTERWAVE (mounted: ${apiPrefix}/payments/flutterwave) ──────────────
  static const String flutterwaveConfig = '/payments/flutterwave/config';
  static const String flutterwaveInit = '/payments/flutterwave/initialize';
  static String flutterwaveVerify(String id) => '/payments/flutterwave/verify/$id';

  // ── NOTIFICATIONS (mounted: ${apiPrefix}/notifications) ───────────────────
  static const String notifications = '/notifications';
  static String markRead(String id) => '/notifications/$id/read';
  static const String unreadCount = '/notifications/unread-count';
  static const String markAllRead = '/notifications/mark-all-read';

  // ── RECEIPTS (mounted at ${apiPrefix} root → receipt.routes.ts) ───────────
  static String transactionReceipt(String id) => '/transactions/$id/receipt';
  static String emailReceipt(String id) => '/transactions/$id/receipt/email';
  static String fundingReceipt(String id) => '/funding/$id/receipt';

  // ── HEALTH ────────────────────────────────────────────────────────────────
  static const String health = '/health';

  // ── ADMIN (/api/v1/admin) ─────────────────────────────────────────────────
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUser(String userId) => '/admin/users/$userId';
  static String blockUser(String userId) => '/admin/users/$userId/block';
  static String unblockUser(String userId) => '/admin/users/$userId/unblock';
  static String creditUser(String userId) => '/admin/users/$userId/credit';
  static String debitUser(String userId) => '/admin/users/$userId/debit';
  static const String adminKycPending = '/admin/kyc/pending';
  static String approveKyc(String documentId) =>
      '/admin/kyc/$documentId/approve';
  static String rejectKyc(String documentId) =>
      '/admin/kyc/$documentId/reject';
  static const String adminTransactions = '/admin/transactions';
  static String adminRefund(String transactionId) =>
      '/admin/transactions/$transactionId/refund';
  static const String floatStatus = '/admin/float/status';
  static const String recordFloat = '/admin/float/record';
  static const String adminFxRates = '/admin/fx-rates';
  static const String fraudFlags = '/admin/fraud/flags';
  static String resolveFlag(String flagId) =>
      '/admin/fraud/flags/$flagId/resolve';
  static const String auditLogs = '/admin/audit-logs';

  // ── B2B PAYOUTS (mounted: ${apiPrefix}/payouts → payout.routes.ts) ──────
  static const String payoutsCreate = '/payouts';
  static String payoutStatus(String jobId) => '/payouts/$jobId';
  static String payoutItems(String jobId) => '/payouts/$jobId/items';
  static const String payoutWebhookTest = '/payouts/webhook-test';
}
