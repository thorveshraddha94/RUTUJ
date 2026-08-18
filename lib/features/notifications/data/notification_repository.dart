import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import '../domain/reminder_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final List<ReminderModel> reminders;
  final bool isLoading;

  const NotificationState({
    required this.notifications,
    required this.reminders,
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    List<ReminderModel>? reminders,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(
          NotificationState(
            notifications: [
              NotificationModel(
                id: 'NOTIF-001',
                title: 'New Airport Transfer Assigned',
                message: 'Booking AT-1048 assigned to Amit Patel. Guest: Rahul Shah. Pickup: Ahmedabad Airport T2 at 10:00 AM.',
                bookingId: 'AT-1048',
                type: NotificationType.driverAssigned,
                timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
                isRead: false,
              ),
              NotificationModel(
                id: 'NOTIF-002',
                title: 'Driver On The Way',
                message: 'Amit Patel started navigation for pickup at Ahmedabad Airport T2.',
                bookingId: 'AT-1048',
                type: NotificationType.driverOnTheWay,
                timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
                isRead: false,
              ),
              NotificationModel(
                id: 'NOTIF-003',
                title: 'Reminder Scheduled',
                message: 'Reminder set for 2 hours before pickup for booking AT-1049.',
                bookingId: 'AT-1049',
                type: NotificationType.reminderSent,
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
                isRead: true,
              ),
            ],
            reminders: [
              ReminderModel(
                id: 'REM-001',
                bookingId: 'AT-1048',
                driverId: 'DRV-101',
                durationLabel: '2 hours',
                scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
                pickupTime: DateTime.now().add(const Duration(hours: 1)),
                notifyPush: true,
                notifySms: true,
                status: 'Sent',
                sentAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ],
          ),
        );

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? bookingId,
  }) {
    final notif = NotificationModel(
      id: 'NOTIF-${100 + state.notifications.length + 1}',
      title: title,
      message: message,
      type: type,
      bookingId: bookingId,
      timestamp: DateTime.now(),
      isRead: false,
    );
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }

  void scheduleReminder({
    required String bookingId,
    required String driverId,
    required String durationLabel,
    required DateTime pickupTime,
    required bool notifyPush,
    required bool notifySms,
  }) {
    final scheduledTime = _calculateScheduledTime(pickupTime, durationLabel);
    final reminder = ReminderModel(
      id: 'REM-${100 + state.reminders.length + 1}',
      bookingId: bookingId,
      driverId: driverId,
      durationLabel: durationLabel,
      scheduledTime: scheduledTime,
      pickupTime: pickupTime,
      notifyPush: notifyPush,
      notifySms: notifySms,
      status: 'Scheduled',
    );

    state = state.copyWith(reminders: [reminder, ...state.reminders]);
  }

  void cancelReminder(String bookingId) {
    final updated = state.reminders.map((r) {
      if (r.bookingId == bookingId && r.status == 'Scheduled') {
        return r.copyWith(status: 'Cancelled');
      }
      return r;
    }).toList();
    state = state.copyWith(reminders: updated);
  }

  DateTime _calculateScheduledTime(DateTime pickup, String label) {
    if (label.contains('15 min')) return pickup.subtract(const Duration(minutes: 15));
    if (label.contains('30 min')) return pickup.subtract(const Duration(minutes: 30));
    if (label.contains('1 hour')) return pickup.subtract(const Duration(hours: 1));
    if (label.contains('2 hour')) return pickup.subtract(const Duration(hours: 2));
    if (label.contains('6 hour')) return pickup.subtract(const Duration(hours: 6));
    if (label.contains('12 hour')) return pickup.subtract(const Duration(hours: 12));
    if (label.contains('24 hour')) return pickup.subtract(const Duration(hours: 24));
    return pickup.subtract(const Duration(hours: 2));
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
