class ReminderModel {
  final String id;
  final String bookingId;
  final String driverId;
  final String durationLabel; // '15 minutes', '2 hours', etc.
  final DateTime scheduledTime;
  final DateTime pickupTime;
  final bool notifyPush;
  final bool notifySms;
  final String status; // 'Scheduled', 'Sent', 'Cancelled'
  final DateTime? sentAt;

  const ReminderModel({
    required this.id,
    required this.bookingId,
    required this.driverId,
    required this.durationLabel,
    required this.scheduledTime,
    required this.pickupTime,
    required this.notifyPush,
    required this.notifySms,
    required this.status,
    this.sentAt,
  });

  ReminderModel copyWith({
    String? id,
    String? bookingId,
    String? driverId,
    String? durationLabel,
    DateTime? scheduledTime,
    DateTime? pickupTime,
    bool? notifyPush,
    bool? notifySms,
    String? status,
    DateTime? sentAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      driverId: driverId ?? this.driverId,
      durationLabel: durationLabel ?? this.durationLabel,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      pickupTime: pickupTime ?? this.pickupTime,
      notifyPush: notifyPush ?? this.notifyPush,
      notifySms: notifySms ?? this.notifySms,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
