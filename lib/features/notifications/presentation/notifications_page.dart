import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/notification_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Center',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${notifState.unreadCount} unread system notifications',
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
              if (notifState.unreadCount > 0)
                OutlinedButton.icon(
                  onPressed: () => notifier.markAllAsRead(),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark All Read'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Notifications List Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: notifState.notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No notifications received yet.', style: TextStyle(color: AppColors.secondaryText)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifState.notifications.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final item = notifState.notifications[index];

                      return Container(
                        color: item.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.06),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: const Icon(Icons.notifications, color: AppColors.primary, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ]
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp),
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: item.bookingId != null
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                                  onPressed: () {
                                    notifier.markAsRead(item.id);
                                    context.go('/admin/bookings/${item.bookingId}');
                                  },
                                )
                              : null,
                          onTap: () {
                            notifier.markAsRead(item.id);
                            if (item.bookingId != null) {
                              context.go('/admin/bookings/${item.bookingId}');
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
