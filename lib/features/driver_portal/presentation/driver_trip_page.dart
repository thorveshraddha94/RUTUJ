import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverTripPage extends StatefulWidget {
  final String token;
  const DriverTripPage({super.key, required this.token});

  @override
  State<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends State<DriverTripPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _booking;
  String? _errorMessage;

  late String _currentToken;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token.isNotEmpty
        ? widget.token
        : (Uri.base.queryParameters['token'] ?? '');
    _loadTrip(_currentToken);
  }

  Future<void> _loadTrip([String? tokenOverride]) async {
    final token = tokenOverride ?? _currentToken;
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid or missing trip token.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      dynamic res;
      try {
        res = await _supabase
            .from('bookings')
            .select('*, vehicles(*)')
            .or('trip_token.eq.$token,id.eq.$token')
            .maybeSingle();
      } catch (_) {
        res = null;
      }

      if (res == null) {
        res = await _supabase
            .from('bookings')
            .select('*')
            .or('trip_token.eq.$token,id.eq.$token')
            .maybeSingle();
      }

      if (res == null) {
        setState(() {
          _errorMessage = 'Trip not found or expired.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _booking = Map<String, dynamic>.from(res as Map);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trip details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final token = _currentToken;
    if (token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'booking_status': newStatus,
      };
      if (newStatus == 'in_progress') {
        updates['trip_started_at'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'completed') {
        updates['trip_completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('bookings')
          .update(updates)
          .or('trip_token.eq.$token,id.eq.$token');

      await _loadTrip(token);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Text(
            _errorMessage ?? 'Trip details unavailable',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final status = (_booking!['status'] ?? 'pending').toString().toLowerCase();
    final passengerName =
        _booking!['passenger_name'] ?? _booking!['guest_name'] ?? 'Passenger';
    final passengerPhone =
        _booking!['passenger_phone'] ?? _booking!['guest_mobile'] ?? '';
    final pickup =
        _booking!['pickup_location'] ?? _booking!['origin'] ?? 'Not specified';
    final dropoff =
        _booking!['dropoff_location'] ??
        _booking!['destination'] ??
        'Not specified';
    final rawCode = _booking!['booking_code'] ?? _booking!['id'] ?? 'TRIP';
    final bookingCode = rawCode.toString().length >= 6
        ? rawCode.toString().substring(0, 6).toUpperCase()
        : rawCode.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: Text(
          'Trip #$bookingCode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2541),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getStatusColor(status)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STATUS: ${status.toUpperCase()}',
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Passenger Card
            Card(
              color: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASSENGER DETAILS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      passengerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            passengerPhone,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (passengerPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.phone,
                              color: Colors.greenAccent,
                            ),
                            onPressed: () =>
                                launchUrl(Uri.parse('tel:$passengerPhone')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route Card
            Card(
              color: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROUTE',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.trip_origin,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pickup: $pickup',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('│', style: TextStyle(color: Colors.grey)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dropoff: $dropoff',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            if (status == 'pending' ||
                status == 'assigned' ||
                status == 'confirmed')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.play_arrow,
                  size: 28,
                  color: Colors.white,
                ),
                label: const Text(
                  'START TRIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _updateStatus('in_progress'),
              ),

            if (status == 'in_progress' || status == 'tripstarted')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle,
                  size: 28,
                  color: Colors.white,
                ),
                label: const Text(
                  'COMPLETE TRIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _updateStatus('completed'),
              ),

            if (status == 'completed')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Trip Completed Successfully!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
      case 'tripstarted':
        return Colors.blueAccent;
      case 'completed':
        return Colors.greenAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'in_progress':
      case 'tripstarted':
        return Icons.directions_car;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }
}
