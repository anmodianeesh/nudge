  import 'package:flutter/material.dart';
  import '../../../core/theme/app_theme.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../widgets/common/custom_button.dart';
  import '../chat/chat_screen.dart';
  import '../nudges/premade_nudges_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    // Sample data - will come from database later
    final List<Map<String, dynamic>> todayHabits = [
      {
        'title': 'Drink water',
        'streak': 5,
        'completed': false,
        'category': 'Health',
        'icon': Icons.water_drop,
      },
      {
        'title': '1 minute meditation',
        'streak': 12,
        'completed': true,
        'category': 'Mindfulness',
        'icon': Icons.self_improvement,
      },
      {
        'title': 'Write 1 sentence',
        'streak': 3,
        'completed': false,
        'category': 'Creativity',
        'icon': Icons.edit,
      },
    ];

    @override
    Widget build(BuildContext context) {
      final completedToday = todayHabits.where((h) => h['completed']).length;
      final totalHabits = todayHabits.length;
      
      return Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                // Progress Overview
                _buildProgressCard(completedToday, totalHabits),
                
                // Quick Actions
                _buildQuickActions(context),
                
                // Today's Habits
                _buildTodayHabits(),
                
                // Recent AI Insights
                _buildAIInsights(),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildHeader() {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()},',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                ),
                const Text(
                  'Ready to grow?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
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
              child: const Icon(
                Icons.person_outline,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildProgressCard(int completed, int total) {
      final progress = total > 0 ? completed / total : 0.0;
      
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingSmall,
        ),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cardWhite,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.cardWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cardWhite),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              progress == 1.0 
                  ? 'Perfect day! All habits completed 🎉'
                  : progress > 0.5 
                      ? 'Great progress! Keep it up!'
                      : 'Let\'s build some momentum today',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.cardWhite.withOpacity(0.9),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildQuickActions(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.psychology_rounded,
                    title: 'AI Coach',
                    subtitle: 'Get personalized nudges',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.library_books_rounded,
                    title: 'Browse Habits',
                    subtitle: 'Explore templates',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PremadeNudgesScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildActionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
              Icon(
                icon,
                size: 32,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildTodayHabits() {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Habits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...todayHabits.map((habit) => _buildHabitCard(habit)),
          ],
        ),
      );
    }

    Widget _buildHabitCard(Map<String, dynamic> habit) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            // Checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  habit['completed'] = !habit['completed'];
                  if (habit['completed']) {
                    habit['streak'] = habit['streak'] + 1;
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: habit['completed'] 
                      ? AppTheme.primaryPurple 
                      : Colors.transparent,
                  border: Border.all(
                    color: habit['completed'] 
                        ? AppTheme.primaryPurple 
                        : AppTheme.borderGray,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: habit['completed']
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.cardWhite,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            
            // Habit Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                habit['icon'],
                color: AppTheme.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Habit Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: habit['completed'] 
                          ? AppTheme.textGray 
                          : AppTheme.textDark,
                      decoration: habit['completed'] 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${habit['streak']} day streak • ${habit['category']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            
            // Streak badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${habit['streak']}🔥',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildAIInsights() {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primaryPurple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your AI Coach says:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You\'re most consistent with habits in the morning. Try stacking your new meditation habit after your water routine for better success.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                    child: const Text(
                      'Chat with your AI →',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'morning';
      if (hour < 17) return 'afternoon';
      return 'evening';
    }
  }