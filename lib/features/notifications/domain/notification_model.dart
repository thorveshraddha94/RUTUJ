enum NotificationType {
  newBooking,
  driverAssigned,
  reminderSent,
  driverAccepted,
  driverOnTheWay,
  driverArrived,
  guestPickedUp,
  tripCompleted,
  bookingCancelled,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? bookingId;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.bookingId,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? bookingId,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
