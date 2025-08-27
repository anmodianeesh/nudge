import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import '../../../data/models/nudge_model.dart';
import '../../widgets/common/custom_button.dart';
import '../chat/chat_screen.dart';
import '../nudges/premade_nudges_screen.dart';
// import '../nudges/my_nudges_screen.dart'; // if you have this screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  IconData _getIconForName(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'medication':
        return Icons.medication;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'air':
        return Icons.air;
      case 'pause_circle':
        return Icons.pause_circle;
      case 'event':
        return Icons.event;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'flag':
        return Icons.flag;
      case 'favorite':
        return Icons.favorite;
      case 'restaurant':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'phone_android':
        return Icons.phone_android;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'notifications_off':
        return Icons.notifications_off;
      case 'bedtime':
        return Icons.bedtime;
      case 'call':
        return Icons.call;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'hearing':
        return Icons.hearing;
      case 'mail':
        return Icons.mail;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health & Wellness':
        return Colors.green;
      case 'Productivity':
        return Colors.blue;
      case 'Mindfulness':
        return Colors.purple;
      case 'Digital Wellness':
        return Colors.orange;
      case 'Social & Relationships':
        return Colors.pink;
      default:
        return AppTheme.primaryPurple;
    }
  }

  Widget _buildShinyButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isGolden = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isGolden
                ? Colors.amber.withOpacity(0.3)
                : AppTheme.primaryPurple.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isGolden
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber.shade300,
                        Colors.yellow.shade600,
                        Colors.orange.shade400,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryPurple.withOpacity(0.8),
                      ],
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverview({
    required int totalNudges,
    required int completedToday,
  }) {
    final pct = totalNudges > 0 ? (completedToday / totalNudges) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.borderGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Counts + chips
          Expanded(
            child: Builder(builder: (context) {
              final state = context.watch<NudgesCubit>().state;
              final total = totalNudges;
              final completed = completedToday;
              final dueNow = 0; // placeholder until schedules
              final dueLater = (total - completed - dueNow).clamp(0, 999);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$completed of $total done',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Due now', value: '$dueNow'),
                      _StatChip(label: 'Due later', value: '$dueLater'),
                      _StatChip(label: 'Streak', value: '0'),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _nextUpCard(BuildContext context, NudgesState state) {
    final active = state.activeMyNudges;
    if (active.isEmpty) return const SizedBox.shrink();

    // Simple heuristic: first incomplete as "Next up".
    final next = active.firstWhere(
      (n) => !state.isCompletedToday(n.id),
      orElse: () => active.first,
    );
    final isDone = state.isCompletedToday(next.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.primaryPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next up', style: TextStyle(color: AppTheme.textGray)),
                  const SizedBox(height: 4),
                  Text(
                    next.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(next.category, style: const TextStyle(color: AppTheme.textGray)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.read<NudgesCubit>().markDoneToday(next.id),
              child: Text(isDone ? 'Undo' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Home',
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
          final completedTodayCount =
              active.where((n) => state.isCompletedToday(n.id)).length;
          final total = active.length;

          final weeklyRates = state.weeklyCompletionRates(days: 7);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Overview (summary ring + chips)
                _buildProgressOverview(
                  totalNudges: total,
                  completedToday: completedTodayCount,
                ),
                const SizedBox(height: 16),

                // Next Up (single actionable nudge)
                _nextUpCard(context, state),
                const SizedBox(height: 16),

                // Mini 7-day completion graph
                
                const SizedBox(height: 8),
                _WeeklyMiniChart(rates: weeklyRates),
                const SizedBox(height: 24),

                // Golden AI button
                _buildShinyButton(
                  context: context,
                  title: 'Ask Nudge',
                  subtitle: 'Get personalized habit advice instantly',
                  icon: Icons.psychology_rounded,
                  isGolden: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Premade nudges button
                _buildShinyButton(
                  context: context,
                  title: 'Browse Nudges',
                  subtitle: 'Discover curated habits for your goals',
                  icon: Icons.lightbulb_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PremadeNudgesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Optional: a "View My Nudges" management CTA
                // SizedBox(
                //   height: 44,
                //   child: OutlinedButton.icon(
                //     icon: const Icon(Icons.list),
                //     onPressed: () {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(builder: (_) => const MyNudgesScreen()),
                //       );
                //     },
                //     label: const Text('View My Nudges'),
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textGray)),
        ],
      ),
    );
  }
}

/// Lightweight, no-deps mini bar chart for 7 days.
/// [rates] must be 7 values between 0..1 (oldest→newest).
class _WeeklyMiniChart extends StatelessWidget {
  final List<double> rates; // 0..1, oldest → newest
  const _WeeklyMiniChart({required this.rates});

  // Tune these to taste — the overall card height will be consistent
  static const double _valueLabelHeight = 14.0;
  static const double _dayLabelHeight = 12.0;
  static const double _graphHeight = 80.0; // bars grow within this
  static const double _barMinHeight = 2.0; // tiny stub for 0%

  @override
  Widget build(BuildContext context) {
    final bars = rates.length >= 7 ? rates.take(7).toList() : List<double>.filled(7, 0.0);
    final now = DateTime.now();
    final weekdayLabels = List<String>.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
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
            const Text(
              'This week',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Fixed-height chart block – the bars only grow inside this space
            SizedBox(
              // Total fixed height = value label + gaps + graphHeight + gaps + day label
              height: _valueLabelHeight + 6 + _graphHeight + 6 + _dayLabelHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final v = bars[i].clamp(0.0, 1.0);
                  final barHeight = v == 0 ? _barMinHeight : v * _graphHeight;

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fixed-height value label
                        SizedBox(
                          height: _valueLabelHeight,
                          child: Center(
                            child: Text(
                              '${(v * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Fixed-height graph area: bar aligns to bottom
                        SizedBox(
                          height: _graphHeight,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Fixed-height day label
                        SizedBox(
                          height: _dayLabelHeight,
                          child: Center(
                            child: Text(
                              weekdayLabels[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}