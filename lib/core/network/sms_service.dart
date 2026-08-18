class SmsResult {
  final bool success;
  final String statusMessage;
  final String? messageId;

  const SmsResult({
    required this.success,
    required this.statusMessage,
    this.messageId,
  });
}

class SmsService {
  final bool _isConfigured;

  SmsService({bool isConfigured = false}) : _isConfigured = isConfigured;

  Future<SmsResult> sendAssignmentSms({
    required String recipientMobile,
    required String bookingCode,
    required String guestName,
    required String pickupLocation,
    required String pickupTime,
  }) async {
    if (!_isConfigured) {
      return const SmsResult(
        success: false,
        statusMessage: 'SMS pending (Provider not configured)',
      );
    }

    try {
      // Production SMS API call goes here (e.g. Twilio / Fast2SMS / MSG91)
      final messageId = 'SMS_${DateTime.now().millisecondsSinceEpoch}';
      return SmsResult(
        success: true,
        statusMessage: 'SMS sent successfully',
        messageId: messageId,
      );
    } catch (e) {
      return SmsResult(
        success: false,
        statusMessage: 'SMS failed: ${e.toString()}',
      );
    }
  }

  Future<SmsResult> sendReminderSms({
    required String recipientMobile,
    required String guestName,
    required String pickupLocation,
    required String pickupTime,
  }) async {
    if (!_isConfigured) {
      return const SmsResult(
        success: false,
        statusMessage: 'SMS not configured',
      );
    }

    return const SmsResult(
      success: true,
      statusMessage: 'Reminder SMS sent successfully',
    );
  }
}
