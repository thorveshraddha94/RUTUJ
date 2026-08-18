import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../bookings/data/booking_repository.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);

    final total = bookingState.bookings.length;
    final completed = bookingState.completedBookings.length;
    final cancelled = bookingState.cancelledBookings.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Analytics & Reports',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Performance statistics, driver utilization, and volume metrics',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Overview Metrics Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            childAspectRatio: 2.8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                title: 'Total Transfers',
                value: '$total',
                icon: Icons.analytics_outlined,
                accentColor: AppColors.primary,
              ),
              StatCard(
                title: 'Completed Transfers',
                value: '$completed',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.success,
              ),
              StatCard(
                title: 'Cancellation Rate',
                value: total > 0 ? '${((cancelled / total) * 100).toStringAsFixed(1)}%' : '0%',
                icon: Icons.pie_chart_outline,
                accentColor: AppColors.danger,
              ),
              const StatCard(
                title: 'On-Time Performance',
                value: '98.4%',
                icon: Icons.airport_shuttle_outlined,
                accentColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Visual Analytics Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  children: [
                    Expanded(child: _buildVolumeBarChart()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStatusPieChart(completed, cancelled, total - completed - cancelled)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildVolumeBarChart(),
                    const SizedBox(height: 24),
                    _buildStatusPieChart(completed, cancelled, total - completed - cancelled),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Transfer Volume Trends',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text('Weekly volume distribution', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(color: AppColors.secondaryText, fontSize: 11));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 12),
                  _barGroup(1, 15),
                  _barGroup(2, 18),
                  _barGroup(3, 14),
                  _barGroup(4, 19),
                  _barGroup(5, 11),
                  _barGroup(6, 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatusPieChart(int completed, int cancelled, int active) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Status Breakdown',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text('Proportion of completed, in-progress, and cancelled trips', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppColors.success,
                    value: completed > 0 ? completed.toDouble() : 1,
                    title: 'Completed',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: active > 0 ? active.toDouble() : 1,
                    title: 'Active',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  PieChartSectionData(
                    color: AppColors.danger,
                    value: cancelled > 0 ? cancelled.toDouble() : 1,
                    title: 'Cancelled',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
