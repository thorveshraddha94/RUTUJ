import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/booking_repository.dart';

class CancelBookingDialog extends ConsumerStatefulWidget {
  final String bookingId;

  const CancelBookingDialog({super.key, required this.bookingId});

  @override
  ConsumerState<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends ConsumerState<CancelBookingDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleCancel() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(bookingProvider.notifier).cancelBooking(
          bookingId: widget.bookingId,
          reason: _reasonController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${widget.bookingId} cancelled successfully.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Text(
            'Cancel Booking ${widget.bookingId}',
            style: const TextStyle(color: AppColors.primaryText, fontSize: 18),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking? This will notify the assigned driver and cancel all pending reminders.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason *',
                hintText: 'e.g., Flight cancelled / Guest requested cancellation',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid cancellation reason';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Booking'),
        ),
        ElevatedButton(
          onPressed: _handleCancel,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Cancel Booking'),
        ),
      ],
    );
  }
}
