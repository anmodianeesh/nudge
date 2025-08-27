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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedToday/$totalNudges',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const Text(
                      'Nudges completed',
                      style: TextStyle(fontSize: 14, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
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
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildActiveNudgeCard({
    required BuildContext context,
    required Nudge nudge,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(nudge.category).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(nudge.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForName(nudge.icon),
              color: _getCategoryColor(nudge.category),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nudge.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () =>
                context.read<NudgesCubit>().markDoneToday(nudge.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted ? Colors.green : AppTheme.borderGray,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: isCompleted ? Colors.green : AppTheme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDone(String id) {
    // This gets the nearest context via BlocProvider.of in build()
    // (We’ll call this from the onTap above using a closure.)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text(
          'My Habits',
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
          // --- Derive data from the current NudgesState (no type checks needed) ---
          final active = state.activeMyNudges; // from your current state
          final completedTodayCount = active
              .where((n) => state.isCompletedToday(n.id))
              .length;
          final total = active.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Overview
                _buildProgressOverview(
                  totalNudges: total,
                  completedToday: completedTodayCount,
                ),
                const SizedBox(height: 24),

                // AI Assistant Button (Golden/Shiny)
                _buildShinyButton(
                  context: context,
                  title: 'Ask Nudge',
                  subtitle: 'Get personalized habit advice instantly',
                  icon: Icons.psychology_rounded,
                  isGolden: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Premade Nudges Button
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
                const SizedBox(height: 32),

                // Active Nudges Section
                const Text(
                  'Active Nudges',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                if (total > 0)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: active.length,
                    itemBuilder: (context, index) {
                      final n = active[index];
                      final isCompleted = state.isCompletedToday(n.id);
                      return _buildActiveNudgeCard(
  context: context,
  nudge: n,
  isCompleted: isCompleted,
);

                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.psychology_alt_outlined,
                          size: 48,
                          color: AppTheme.textGray.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No active nudges yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start by asking Nudge for personalized recommendations or browse our curated habits.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
