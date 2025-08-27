import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
          
      ),
      body: BlocBuilder<NudgesCubit, NudgesState>(
        builder: (context, state) {
          final active = state.activeMyNudges;
          final total = active.length;
          final completedToday = active.where((n) => state.isCompletedToday(n.id)).length;
          final weekly = state.weeklyCompletionRates(days: 7);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MetricCard(
                title: "Today's completion",
                value: total == 0 ? '0%' : '${((completedToday / total) * 100).round()}%',
                subtitle: '$completedToday of $total nudges',
              ),
              const SizedBox(height: 12),
              _WeeklyChart(rates: weekly),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Active nudges',
                value: '$total',
                subtitle: 'Currently tracked',
              ),
              // You can add category pie or longest streaks here later
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> rates; // 0..1, oldest → newest
  const _WeeklyChart({required this.rates});

  @override
  Widget build(BuildContext context) {
    final bars = rates.length >= 7 ? rates : List<double>.filled(7, 0.0);
    const maxHeight = 120.0;
    final now = DateTime.now();
    final weekdayLabels = List<String>.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      // Mon, Tue, ...
      return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][day.weekday - 1];
    });

    return Card(
      color: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This week',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  fontSize: 16,
                )),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = bars[i].clamp(0.0, 1.0);
                final h = (v == 0 ? 4 : v * maxHeight);
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(v * 100).round()}%',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weekdayLabels[i],
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
