import 'models/nudge_model.dart';

class PremadeNudgesData {
  static final List<Nudge> _allNudges = [
    // Health & Wellness
    Nudge(
      id: 'hw1',
      title: 'Morning Water',
      description: 'Drink a glass of water immediately after waking up',
      category: 'Health & Wellness',
      icon: 'water_drop',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'hw2',
      title: 'Take Your Vitamins',
      description: 'Remember to take your daily vitamins with breakfast',
      category: 'Health & Wellness',
      icon: 'medication',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'hw3',
      title: '10-Minute Walk',
      description: 'Take a 10-minute walk after lunch to aid digestion',
      category: 'Health & Wellness',
      icon: 'accessibility_new',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'hw4',
      title: 'Healthy Snack',
      description: 'Choose a fruit or nuts instead of processed snacks',
      category: 'Health & Wellness',
      icon: 'restaurant',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'hw5',
      title: 'Posture Check',
      description: 'Check and correct your posture every hour',
      category: 'Health & Wellness',
      icon: 'self_improvement',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    
    // Productivity
    Nudge(
      id: 'pr1',
      title: 'Pomodoro Break',
      description: 'Take a 5-minute break every 25 minutes of focused work',
      category: 'Productivity',
      icon: 'pause_circle',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'pr2',
      title: 'Daily Planning',
      description: 'Spend 10 minutes each morning planning your day',
      category: 'Productivity',
      icon: 'event',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'pr3',
      title: 'Desk Cleanup',
      description: 'Clear your workspace before starting any new task',
      category: 'Productivity',
      icon: 'cleaning_services',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'pr4',
      title: 'Priority Task First',
      description: 'Always tackle your most important task first thing',
      category: 'Productivity',
      icon: 'flag',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    
    // Mindfulness
    Nudge(
      id: 'mf1',
      title: 'Deep Breathing',
      description: 'Take 3 deep breaths before stressful situations',
      category: 'Mindfulness',
      icon: 'air',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'mf2',
      title: 'Gratitude Moment',
      description: 'Think of one thing you\'re grateful for each hour',
      category: 'Mindfulness',
      icon: 'favorite',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'mf3',
      title: 'Mindful Eating',
      description: 'Eat one meal per day without any distractions',
      category: 'Mindfulness',
      icon: 'restaurant',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'mf4',
      title: 'Nature Connection',
      description: 'Look outside or step outdoors for 2 minutes every few hours',
      category: 'Mindfulness',
      icon: 'nature',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    
    // Digital Wellness
    Nudge(
      id: 'dw1',
      title: 'Phone-Free Morning',
      description: 'Don\'t check your phone for the first hour after waking',
      category: 'Digital Wellness',
      icon: 'phone_android',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'dw2',
      title: 'Notification Cleanup',
      description: 'Turn off non-essential notifications on your devices',
      category: 'Digital Wellness',
      icon: 'notifications_off',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'dw3',
      title: 'Digital Sunset',
      description: 'Put devices away 1 hour before bedtime',
      category: 'Digital Wellness',
      icon: 'bedtime',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'dw4',
      title: 'Screen Break',
      description: 'Look away from screens every 20 minutes for 20 seconds',
      category: 'Digital Wellness',
      icon: 'phone_iphone',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    
    // Social & Relationships
    Nudge(
      id: 'sr1',
      title: 'Call Someone',
      description: 'Make one meaningful call to a friend or family member',
      category: 'Social & Relationships',
      icon: 'call',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'sr2',
      title: 'Give a Compliment',
      description: 'Give someone a genuine compliment today',
      category: 'Social & Relationships',
      icon: 'thumb_up',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'sr3',
      title: 'Active Listening',
      description: 'Practice active listening in your next conversation',
      category: 'Social & Relationships',
      icon: 'hearing',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Nudge(
      id: 'sr4',
      title: 'Send a Message',
      description: 'Send a thoughtful message to someone you haven\'t talked to in a while',
      category: 'Social & Relationships',
      icon: 'mail',
      isActive: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
  ];

  static List<Nudge> get allNudges => List.unmodifiable(_allNudges);

  static List<Nudge> getNudgesByCategory(String category) {
    return _allNudges.where((nudge) => nudge.category == category).toList();
  }

  static List<String> get categories {
    return _allNudges
        .map((nudge) => nudge.category)
        .toSet()
        .toList()
      ..sort();
  }

  static Nudge? getNudgeById(String id) {
    try {
      return _allNudges.firstWhere((nudge) => nudge.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Nudge> searchNudges(String query) {
    final lowerQuery = query.toLowerCase();
    return _allNudges.where((nudge) {
      return nudge.title.toLowerCase().contains(lowerQuery) ||
             nudge.description.toLowerCase().contains(lowerQuery) ||
             nudge.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}