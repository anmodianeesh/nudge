// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import '../chat/chat_screen.dart';
import '../nudges/premade_nudges_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ——— Layout constants ———
  static const double _sectionGap = 16.0;
  static const double _actionHubHeight = 158.0; // fixed slot height
  static const double _ctaHeight = 110.0;        // taller CTAs
  static const double _sectionGap2 = 24.0; // consistent vertical spacing


  // ——— Shiny CTA (taller) ———
  Widget _buildShinyButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isGolden = false,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                      AppTheme.primaryPurple.withOpacity(0.85),
                    ],
                  ),
            boxShadow: [
              BoxShadow(
                color:
                    (isGolden ? Colors.amber : AppTheme.primaryPurple).withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // Consistent taller height
          child: SizedBox(
            height: _ctaHeight,
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                      subtitle,
                      maxLines: 2,             // allow 2 lines
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,           // line spacing so it’s readable
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.9), size: 18),
                const SizedBox(width: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ——— Action Hub slot (keeps fixed height; contents swipeable) ———
  Widget _actionHubSlot(BuildContext context, NudgesState state) {
    return SizedBox(
      height: _actionHubHeight,
      child: _ActionHub(state: state),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.textDark),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: BlocBuilder<NudgesCubit, NudgesState>(
        builder: (context, state) {
          final weeklyRates = state.weeklyCompletionRates(days: 7);

          return ListView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            children: [
              // 1) ADD SCHEDULED NUDGE (Action Hub)
              _actionHubSlot(context, state),
              const SizedBox(height: _sectionGap),

              // 2) THIS WEEK ANALYTICS
      
            
              const SizedBox(height: 8),
              _WeeklyMiniChart(rates: weeklyRates),
              const SizedBox(height: _sectionGap2),

              // 3) CTAs
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
              const SizedBox(height: _sectionGap2),
              _buildShinyButton(
                context: context,
                title: 'Browse Nudges',
                subtitle: 'Discover curated habits for your goals',
                icon: Icons.lightbulb_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremadeNudgesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: _sectionGap2),
            ],
          );
        },
      ),
    );
  }
}

/// Constant-size mini bar chart for 7 days (oldest → newest).
class _WeeklyMiniChart extends StatelessWidget {
  final List<double> rates; // 0..1
  const _WeeklyMiniChart({required this.rates});

  static const double _valueLabelHeight = 14.0;
  static const double _dayLabelHeight = 12.0;
  static const double _graphHeight = 80.0;
  static const double _barMinHeight = 2.0;

  @override
  Widget build(BuildContext context) {
    final bars =
        rates.length >= 7 ? rates.take(7).toList() : List<double>.filled(7, 0.0);
    final now = DateTime.now();
    final weekdayLabels = List<String>.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
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
            SizedBox(
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

/// Swipeable Action Hub: shows only actionable (scheduled) nudges.
/// Uses state from NudgesCubit; logging is done via logNow/undoLog.
class _ActionHub extends StatefulWidget {
  final NudgesState state;
  const _ActionHub({required this.state});

  @override
  State<_ActionHub> createState() => _ActionHubState();
}

class _ActionHubState extends State<_ActionHub> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94); // subtle peeks
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionable = widget.state.actionableNudges;

    if (actionable.isEmpty) {
      // Placeholder of SAME height (keeps layout stable)
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.textGray),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a scheduled nudge to start logging from Home',
                style: TextStyle(color: AppTheme.textGray),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: actionable.length,
            onPageChanged: (i) => setState(() => _index = i),
            padEnds: false,
            itemBuilder: (context, i) {
              final n = actionable[i];
              final s = widget.state.schedules[n.id]!;
              final count = widget.state.dailyCountFor(n.id, DateTime.now());
              final target = s.dailyTarget;
              final pct = (target == 0) ? 0.0 : (count / target).clamp(0.0, 1.0);
              final done = count >= target;

              return _ActionCard(
                title: n.title,
                category: n.category,
                progress: pct,
                count: count,
                target: target,
                scheduleKind: s.kind,
                done: done,
                onLog: () {
                  final cubit = context.read<NudgesCubit>();
                  if (done) {
                    cubit.undoLog(n.id);
                  } else {
                    cubit.logNow(n.id);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(actionable.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryPurple : AppTheme.borderGray,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String category;
  final double progress; // 0..1
  final int count;
  final int target;
  final ScheduleKind scheduleKind;
  final bool done;
  final VoidCallback onLog;

  const _ActionCard({
    required this.title,
    required this.category,
    required this.progress,
    required this.count,
    required this.target,
    required this.scheduleKind,
    required this.done,
    required this.onLog,
    super.key,
  });

  static String _scheduleHint(ScheduleKind kind) {
    switch (kind) {
      case ScheduleKind.hourly:
        return 'Hourly check-ins';
      case ScheduleKind.timesPerDay:
        return 'Multiple times today';
      case ScheduleKind.specificTimes:
        return 'Scheduled times';
      case ScheduleKind.continuous:
        return 'All-day (not shown on Home)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Progress ring + icon
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.borderGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple,
                  ),
                ),
              ),
              const Icon(Icons.checklist_rtl, color: AppTheme.primaryPurple),
            ],
          ),
          const SizedBox(width: 12),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textGray),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count / $target today',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  _scheduleHint(scheduleKind),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Log / Undo button (fixed sizing; no weird dots)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 104, minHeight: 40),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(104, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              onPressed: onLog,
              child: Text(
                done ? 'Undo' : 'Log now',
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
