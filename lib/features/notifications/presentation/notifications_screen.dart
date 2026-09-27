import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<NotificationItem> _allNotifications;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allNotifications = _generateNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            // Unread count badge
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.royalGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: AppColors.darkBg,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.royalGold),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Tabs
              GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.royalGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: AppColors.darkBg,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Actions'),
                    Tab(text: 'Security'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupedList(_allNotifications),
                    _buildGroupedList(_allNotifications.where((n) => n.actionButton != null).toList()),
                    _buildGroupedList(_allNotifications.where((n) => n.type == NotificationType.security).toList()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _unreadCount => _allNotifications.where((n) => !n.isRead).length;

  // ══════════════════════════════════════════════════════════════════════════
  //  GROUPED LIST — by date: Today, Yesterday, This Week, Earlier
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGroupedList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final groups = <String, List<NotificationItem>>{};
    for (final n in notifications) {
      final group = _dateGroupLabel(n.timestamp);
      groups.putIfAbsent(group, () => []).add(n);
    }

    // Build flat list with section headers
    final items = <Widget>[];
    for (final entry in groups.entries) {
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            entry.key,
            style: TextStyle(
              color: AppColors.royalGold.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
      // Notification cards
      for (final notification in entry.value) {
        items.add(_buildDismissibleCard(notification));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: items,
    );
  }

  String _dateGroupLabel(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return 'THIS WEEK';
    return 'EARLIER';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DISMISSIBLE CARD — swipe to delete with undo
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDismissibleCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger.withValues(alpha: 0.8)),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(color: AppColors.danger.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        final removedItem = notification;
        final removedIndex = _allNotifications.indexOf(removedItem);

        setState(() {
          _allNotifications.remove(removedItem);
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification removed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forestDepths,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.royalGold,
              onPressed: () {
                setState(() {
                  if (removedIndex >= 0 && removedIndex <= _allNotifications.length) {
                    _allNotifications.insert(removedIndex, removedItem);
                  } else {
                    _allNotifications.add(removedItem);
                  }
                });
              },
            ),
          ),
        );
      },
      child: _buildNotificationCard(notification),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NOTIFICATION CARD — with action button
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNotificationCard(NotificationItem notification) {
    return GestureDetector(
      onTap: () {
        // Mark as read on tap
        if (!notification.isRead) {
          setState(() {
            final index = _allNotifications.indexOf(notification);
            if (index >= 0) {
              _allNotifications[index] = notification.copyWith(isRead: true);
            }
          });
        }
        // Execute default tap action
        notification.onTap?.call(context);
      },
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with notification type color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getNotificationColor(notification.type).withValues(alpha: 0.15),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      // Unread pulse dot
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.royalGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.royalGold.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.8, end: 1.2, duration: 1200.ms),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── Action Button ─────────────────────────────
                  if (notification.actionButton != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => notification.actionButton!.onTap(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: notification.actionButton!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: notification.actionButton!.color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              notification.actionButton!.icon,
                              color: notification.actionButton!.color,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notification.actionButton!.label,
                              style: TextStyle(
                                color: notification.actionButton!.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NOTIFICATION DATA — B2B professional templates
  // ══════════════════════════════════════════════════════════════════════════

  List<NotificationItem> _generateNotifications() {
    return [
      // ── Payout Received (Actionable) ──────────────────────
      NotificationItem(
        id: 'txn1',
        title: 'B2B Payroll Deposited',
        message: '\$1,500.00 USD from Deel Inc. has safely hit your secure holding ledger via Ecobank. Funds are available for immediate FX swap or withdrawal.',
        type: NotificationType.payoutReceived,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
        actionButton: NotificationAction(
          label: 'View Funds',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.royalGold,
          onTap: (ctx) => ctx.push('/wallet'),
        ),
      ),

      // ── FX Quote Locked (Actionable with urgency) ─────────
      NotificationItem(
        id: 'txn2',
        title: 'FX Rate Locked — Convert Now',
        message: 'Your USD → GHS rate of 15.08 has been locked for 60 seconds. Convert now before the quote expires.',
        type: NotificationType.fxQuoteLocked,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: false,
        actionButton: NotificationAction(
          label: 'Convert Now',
          icon: Icons.currency_exchange_rounded,
          color: const Color(0xFFFF9800),
          onTap: (ctx) => ctx.push('/fx-convert'),
        ),
      ),

      // ── Claim Available (Actionable) ──────────────────────
      NotificationItem(
        id: 'txn3',
        title: 'Funds Waiting — Claim Your Account',
        message: 'You\'ve been sent ₵450.00 via VessPay. Create your account in 30 seconds to claim your funds.',
        type: NotificationType.claimAvailable,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        actionButton: NotificationAction(
          label: 'Claim My Funds',
          icon: Icons.card_giftcard_rounded,
          color: AppColors.successGreen,
          onTap: (ctx) => ctx.push('/claim?phone=+233240000000&token=demo-claim-token'),
        ),
      ),

      // ── Transfer Completed (Actionable) ───────────────────
      NotificationItem(
        id: 'txn4',
        title: 'Mobile Money Cashout',
        message: '₵500.00 GHS disbursed to MTN MoMo ending 4567. Transaction settled via Ecobank payment rail.',
        type: NotificationType.transaction,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        actionButton: NotificationAction(
          label: 'View Receipt',
          icon: Icons.receipt_long_rounded,
          color: Colors.blue.shade300,
          onTap: (ctx) => ctx.push('/transaction-history'),
        ),
      ),

      // ── Corporate Payout ──────────────────────────────────
      NotificationItem(
        id: 'txn5',
        title: 'Corporate Payout Received',
        message: '\$850.00 USD from Toptal LLC has been credited to your secure USD holding wallet. Protected from local currency volatility.',
        type: NotificationType.payoutReceived,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionButton: NotificationAction(
          label: 'View Funds',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.royalGold,
          onTap: (ctx) => ctx.push('/wallet'),
        ),
      ),

      // ── Exchange Successful ───────────────────────────────
      NotificationItem(
        id: 'txn6',
        title: 'Exchange Successful',
        message: 'Liquidated \$100.00 USD to 1,520.00 GHS at a locked wholesale treasury rate. Your local spending account has been credited.',
        type: NotificationType.transaction,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionButton: NotificationAction(
          label: 'View Receipt',
          icon: Icons.receipt_long_rounded,
          color: Colors.blue.shade300,
          onTap: (ctx) => ctx.push('/transaction-history'),
        ),
      ),

      // ── QR Payment ────────────────────────────────────────
      NotificationItem(
        id: 'txn7',
        title: 'QR Payment Completed',
        message: '₵75.00 GHS paid to Accra Mall Merchant via QR scan. Deducted from your local GHS spending account.',
        type: NotificationType.transaction,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),

      // ── Security: Biometric Login ─────────────────────────
      NotificationItem(
        id: 'sec1',
        title: 'Biometric Login Verified',
        message: 'Face ID authentication was used to access your account from iPhone 15 Pro in Accra, Ghana.',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),

      // ── Security: KYC Upgrade (Actionable) ────────────────
      NotificationItem(
        id: 'sec2',
        title: 'KYC Tier Upgraded',
        message: 'Your Ecobank Tier 3 compliance status has been fully verified. Daily transfer limits increased to ₵10,000.',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionButton: NotificationAction(
          label: 'View Limits',
          icon: Icons.speed_rounded,
          color: AppColors.info,
          onTap: (ctx) => ctx.push('/transaction-limits'),
        ),
      ),

      // ── Security: New Device (Actionable) ─────────────────
      NotificationItem(
        id: 'sec3',
        title: 'New Device Login',
        message: 'Your account was accessed from Chrome on Windows. If this wasn\'t you, secure your account immediately.',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        actionButton: NotificationAction(
          label: 'Review Settings',
          icon: Icons.shield_rounded,
          color: AppColors.errorRed,
          onTap: (ctx) => ctx.push('/security'),
        ),
      ),

      // ── System: Direct Deposit Active (Actionable) ────────
      NotificationItem(
        id: 'onb1',
        title: 'Setup Complete: Direct Deposit Active',
        message: 'Your virtual US routing numbers are active. Copy your direct deposit info straight into Upwork, Deel, or any freelance platform to receive payroll automatically.',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        actionButton: NotificationAction(
          label: 'Copy Routing Details',
          icon: Icons.copy_rounded,
          color: AppColors.info,
          onTap: (ctx) {
            Clipboard.setData(const ClipboardData(
              text: 'Bank: VessPay Digital (via Ecobank)\nRouting: 084009519\nAccount: VP-8801234567\nType: Checking',
            ));
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: const Text('US routing details copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
        ),
      ),

      // ── System: Multi-Currency Active ─────────────────────
      NotificationItem(
        id: 'onb4',
        title: 'Multi-Currency Wallet Active',
        message: 'Your USD and local currency wallets are live. Hold stable dollars to defend against inflation, then swap at wholesale treasury rates.',
        type: NotificationType.promotion,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Icons.payment_rounded;
      case NotificationType.security:
        return Icons.security_rounded;
      case NotificationType.promotion:
        return Icons.rocket_launch_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
      case NotificationType.payoutReceived:
        return Icons.account_balance_rounded;
      case NotificationType.fxQuoteLocked:
        return Icons.lock_clock_rounded;
      case NotificationType.claimAvailable:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return AppColors.royalGold;
      case NotificationType.security:
        return AppColors.errorRed;
      case NotificationType.promotion:
        return AppColors.successGreen;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.payoutReceived:
        return AppColors.royalGold;
      case NotificationType.fxQuoteLocked:
        return const Color(0xFFFF9800);
      case NotificationType.claimAvailable:
        return AppColors.successGreen;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _markAllAsRead() {
    setState(() {
      _allNotifications = _allNotifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum NotificationType {
  transaction,
  security,
  promotion,
  system,
  payoutReceived,
  fxQuoteLocked,
  claimAvailable,
}

/// Action button that appears inside a notification card.
class NotificationAction {
  final String label;
  final IconData icon;
  final Color color;
  final void Function(BuildContext) onTap;

  const NotificationAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final NotificationAction? actionButton;
  final String? actionLabel; // legacy — kept for backward compat
  final void Function(BuildContext)? onTap;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.actionButton,
    this.actionLabel,
    this.onTap,
  });

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionButton: actionButton,
      actionLabel: actionLabel,
      onTap: onTap,
    );
  }
}
