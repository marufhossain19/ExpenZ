import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/formatters.dart';

/// Animated notification bell icon with unread badge count.
class NotificationBell extends StatelessWidget {
  final VoidCallback? onTap;

  const NotificationBell({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: onTap ?? () => _showNotificationSheet(context, provider),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 26),
              if (provider.hasUnread)
                Positioned(
                  top: -4, right: -4,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (_, val, child) => Transform.scale(scale: val, child: child),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.expense,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          provider.unreadCount > 9 ? '9+' : '${provider.unreadCount}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, NotificationProvider _) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer<NotificationProvider>(
        builder: (ctx, provider, _) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2)),
            )),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  if (provider.notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(context, provider),
                      child: const Text('Clear All', style: TextStyle(fontSize: 13, color: AppColors.expense, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            // List
            Expanded(
              child: provider.notifications.isEmpty
                ? Center(child: Text('No notifications yet', style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)))
                : ListView.builder(
                    itemCount: provider.notifications.length,
                    key: ValueKey(provider.notifications.length),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) {
                      final n = provider.notifications[i];
                      final tIndex =
                          n.type < 0 || n.type >= 4 ? 0 : n.type;
                      final pendingInvite =
                          n.type == 3 && n.inviteStatus == 'pending';
                      final typeIcon = [
                        Icons.account_balance_wallet_rounded,
                        Icons.family_restroom_rounded,
                        Icons.lightbulb_rounded,
                        Icons.mail_rounded,
                      ];
                      final typeColor = [
                        AppColors.primary,
                        AppColors.secondary,
                        const Color(0xFFFFA502),
                        AppColors.accent,
                      ];
                      
                      return Slidable(
                        key: ValueKey(n.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => provider.deleteNotification(n.id),
                              backgroundColor: AppColors.expense,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Delete',
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ],
                        ),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => provider.deleteNotification(n.id),
                              backgroundColor: AppColors.expense,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Delete',
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: !n.isRead 
                                ? (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                                : (isDark ? AppColors.darkCard : AppColors.lightCard),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: !n.isRead
                                  ? typeColor[tIndex].withValues(alpha: 0.4)
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: pendingInvite
                                    ? null
                                    : () => provider.markRead(n.id),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: typeColor[tIndex].withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(typeIcon[tIndex], size: 20, color: typeColor[tIndex]),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.body,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.3,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  Formatters.relativeDateWithTime(n.timestamp),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                ),
                                                if (!n.isRead) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 6, height: 6,
                                                    decoration: BoxDecoration(
                                                      color: typeColor[tIndex],
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => provider.deleteNotification(n.id),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (pendingInvite) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final success = await provider.rejectInvite(n.id);
                                          if (context.mounted && !success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to reject invite')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.expense,
                                          side: const BorderSide(color: AppColors.expense),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final success = await provider.acceptInvite(n.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success ? 'Family invite accepted' : 'Failed to accept invite',
                                                ),
                                                backgroundColor: success ? AppColors.income : AppColors.expense,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check_rounded, size: 16),
                                        label: const Text('Accept', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.income,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          visualDensity: VisualDensity.compact,
                                          elevation: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (n.type == 3 && n.inviteStatus != null && n.inviteStatus != 'pending') ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: n.inviteStatus == 'accepted'
                                            ? AppColors.income.withValues(alpha: 0.12)
                                            : AppColors.expense.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        n.inviteStatus == 'accepted' ? 'Accepted' : 'Rejected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: n.inviteStatus == 'accepted' ? AppColors.income : AppColors.expense,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ));
  }

  void _confirmClear(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all notifications.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearAll();
            },
            child: const Text('Clear All',
                style: TextStyle(
                    color: AppColors.expense, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
