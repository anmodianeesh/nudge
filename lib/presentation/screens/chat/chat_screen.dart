// lib/presentation/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/nudge_model.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(role: MessageRole.user, text: trimmed, time: DateTime.now()));
      _controller.clear();
    });

    setState(() => _isTyping = true);

    try {
      // Always show AI response first
      await Future.delayed(const Duration(milliseconds: 800));
      
      final aiResponse = _generateAIResponse(trimmed);
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: aiResponse,
          time: DateTime.now(),
        ));
      });

      // Then check if user wants to create a nudge
      if (_shouldCreateNudge(trimmed)) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _maybeCreateNudgeFromText(trimmed);
      }

    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: "Sorry, I had trouble processing that. Please try again.",
          time: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      ChatArchive.autosaveFromMessages(_messages);
      _scrollToBottom();
    }
  }

  String _generateAIResponse(String userText) {
    final lower = userText.toLowerCase();
    
    if (lower.contains('water') || lower.contains('hydrate')) {
      return "Great thinking! Staying hydrated is one of the simplest yet most impactful habits. I'd suggest starting with one glass right now, then another after lunch. Would you like me to create a gentle reminder system for this?";
    }
    if (lower.contains('sleep') || lower.contains('tired')) {
      return "Sleep is the foundation of everything else. A simple 10-minute wind-down routine at 21:30 can work wonders - maybe just putting your phone on the charger in another room. Should I set up a reminder for this?";
    }
    if (lower.contains('exercise') || lower.contains('workout') || lower.contains('fitness')) {
      return "Movement doesn't have to be overwhelming! Even 10 jumping jacks or a 2-minute walk can break the pattern and energize you. The key is consistency over intensity. Want me to create a simple movement nudge?";
    }
    if (lower.contains('study') || lower.contains('learn') || lower.contains('focus')) {
      return "Try a 2-minute focus sprint: just open the document and add one bullet point. That's it. The hardest part is often just starting. Should I help you build this micro-habit?";
    }
    if (lower.contains('family') || lower.contains('parent') || lower.contains('kids')) {
      return "Family time is precious and often the first thing that gets squeezed out. What if we started with just one intentional moment - maybe asking 'What was the best part of your day?' at dinner? I can remind you.";
    }
    if (lower.contains('friend') || lower.contains('social') || lower.contains('lonely')) {
      return "Friendships need nurturing, like plants. A quick text or 2-minute call can make someone's day - and yours too. Sometimes we overthink it. Want me to nudge you to reach out?";
    }
    if (lower.contains('work') || lower.contains('productivity') || lower.contains('meeting')) {
      return "Work can feel overwhelming without structure. Try spending 2 minutes at the end of each day reviewing tomorrow's priorities. It's amazing how much clarity this brings. Should I set up a reminder?";
    }
    if (lower.contains('stress') || lower.contains('anxiety') || lower.contains('overwhelm')) {
      return "When things feel overwhelming, the answer is usually to go smaller, not bigger. What's one tiny thing you could do right now to feel a bit more grounded? Even taking 3 deep breaths counts.";
    }
    if (lower.contains('habit') || lower.contains('routine') || lower.contains('remind me')) {
      return "I love that you're thinking about building better habits! The secret is starting ridiculously small. What's something tiny you could do consistently? I'm here to help you stick with it.";
    }
    
    // Default responses
    final responses = [
      "I hear you. Let's turn this into a tiny step you can actually do today. What comes to mind?",
      "That sounds important to you. What would success look like if we started with just 2 minutes a day?",
      "Got it. The key is finding something so small it feels almost silly not to do it. What might that be?",
      "Sometimes the best action is the smallest one. What's one micro-step we could try?",
      "I'm here to help you build lasting change through tiny, consistent actions. What matters most to you right now?",
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  bool _shouldCreateNudge(String text) {
    final lower = text.toLowerCase();
    return lower.contains('remind me') || 
           lower.contains('create') ||
           lower.contains('help me') ||
           lower.contains('habit') ||
           lower.contains('routine') ||
           lower.contains('water') ||
           lower.contains('sleep') ||
           lower.contains('exercise') ||
           lower.contains('study') ||
           lower.contains('family') ||
           lower.contains('friend') ||
           lower.contains('work');
  }

  Future<void> _maybeCreateNudgeFromText(String text) async {
    if (!_shouldCreateNudge(text)) return;

    try {
      // Generate a nudge spec based on the text
      final spec = _generateNudgeFromText(text);
      
      if (!mounted) return;

      // Show confirmation & editing sheet (returns edited spec or null if cancelled)
      final edited = await showModalBottomSheet<NudgeSpec>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.cardWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _ConfirmNudgeSheet(spec: spec),
      );

      if (edited == null) return;

      // 1) Show user's confirmation as a reply message
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.user,
          text: _formatUserConfirmation(edited),
          time: DateTime.now(),
        ));
      });

      // 2) Create the nudge from the edited spec
      await _createNudge(edited);

      // 3) Show success feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nudge created successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // 4) Add a follow-up AI message
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: "Perfect! I've created that nudge for you. You'll find it in your 'My Nudges' section, and it'll start helping you build this habit. Remember, consistency beats perfection!",
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Couldn\'t create nudge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _formatUserConfirmation(NudgeSpec spec) {
    final scheduleText = spec.scheduleType == 'times_per_day' 
        ? '${spec.targetCount}x per day' 
        : spec.scheduleType;
    
    return 'Perfect! Create nudge "${spec.title}" (${spec.category}) — $scheduleText.\n\n'
           'Reminder: ${spec.reminderText}\n'
           'Action: ${spec.description}';
  }

  NudgeSpec _generateNudgeFromText(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('water') || lower.contains('hydrate')) {
      return NudgeSpec(
        title: "Stay Hydrated",
        description: "Drink one glass of water",
        category: "Health",
        targetCount: 8,
        scheduleType: "times_per_day",
        reminderText: "Hydration time! 💧 Time for a glass of water.",
      );
    } else if (lower.contains('sleep') || lower.contains('tired')) {
      return NudgeSpec(
        title: "Better Sleep Routine",
        description: "Put phone on charger outside bedroom",
        category: "Health",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Wind-down time 🌙 Let's prepare for better sleep.",
      );
    } else if (lower.contains('exercise') || lower.contains('workout')) {
      return NudgeSpec(
        title: "Daily Movement",
        description: "Do 10 jumping jacks or 2-minute walk",
        category: "Fitness",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Let's get moving! 💪 Just 2 minutes of movement.",
      );
    } else if (lower.contains('family')) {
      return NudgeSpec(
        title: "Connect with Family",
        description: "Ask someone 'What was the best part of your day?'",
        category: "Personal",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Family connection time! ❤️ Show someone you care.",
      );
    } else if (lower.contains('friend')) {
      return NudgeSpec(
        title: "Stay Connected",
        description: "Send a quick message to a friend",
        category: "Personal",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Friendship check-in! 👋 Reach out to someone.",
      );
    } else if (lower.contains('work') || lower.contains('productivity')) {
      return NudgeSpec(
        title: "Work Planning",
        description: "Review tomorrow's top 3 priorities",
        category: "Productivity",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Quick planning session 📋 Set tomorrow up for success.",
      );
    } else if (lower.contains('study') || lower.contains('learn')) {
      return NudgeSpec(
        title: "Learning Habit",
        description: "Open study material and write one note",
        category: "Productivity",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Learning time! 📚 Just one small step forward.",
      );
    } else {
      return NudgeSpec(
        title: "Daily Habit",
        description: "Take one small positive action",
        category: "Personal",
        targetCount: 1,
        scheduleType: "daily",
        reminderText: "Time for your daily habit! ✨",
      );
    }
  }

  Future<void> _createNudge(NudgeSpec spec) async {
    // Convert the spec to a Nudge and add it to the cubit
    final newNudge = Nudge(
      id: 'ai_nudge_${DateTime.now().millisecondsSinceEpoch}',
      title: spec.title,
      description: spec.description,
      category: spec.category,
      icon: _getCategoryIcon(spec.category),
      isActive: true,
      createdAt: DateTime.now(), 
      createdBy: '', frequency: '',
    );

    // Determine schedule
    final scheduleKind = spec.scheduleType == 'times_per_day' 
        ? ScheduleKind.timesPerDay 
        : ScheduleKind.timesPerDay; // Default to times per day
    
    final schedule = NudgeScheduleSimple(
      kind: scheduleKind,
      dailyTarget: spec.targetCount,
    );

    // Add to cubit
    final cubit = context.read<NudgesCubit>();
    
    // First add to allNudges, then to myNudges with schedule
    final currentNudges = List<Nudge>.from(cubit.state.allNudges);
    currentNudges.add(newNudge);
    
    cubit.emit(cubit.state.copyWith(allNudges: currentNudges));
    cubit.addToMyNudges(newNudge.id);
    cubit.setSchedule(newNudge.id, schedule);
    
    print('Created AI nudge: ${newNudge.title} with schedule ${schedule.dailyTarget}x per day');
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return '💧';
      case 'fitness':
        return '💪';
      case 'productivity':
        return '📋';
      case 'personal':
        return '✨';
      default:
        return '🎯';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openHistory() async {
    final picked = await Navigator.of(context).push<ChatSession>(
      MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
    );
    if (picked != null) {
      setState(() {
        _messages
          ..clear()
          ..addAll(picked.messages);
      });
      _scrollToBottom();
    }
  }

  void _newChat() {
    if (_messages.isNotEmpty) ChatArchive.saveSessionFromMessages(_messages);
    setState(() {
      _messages.clear();
      _isTyping = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final empty = _messages.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Text(
          empty ? 'AI Coach' : 'Chat with Nudge',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Previous chats',
            icon: const Icon(Icons.history_rounded),
            onPressed: _openHistory,
          ),
          if (!empty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: _newChat,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: empty ? _WelcomePane(
          key: const ValueKey('welcome'),
          controller: _controller,
          onSend: _send,
          onHistoryTap: _openHistory,
        ) : _ChatPane(
          key: const ValueKey('chat'),
          messages: _messages,
          isTyping: _isTyping,
          controller: _controller,
          scrollController: _scrollController,
          onSend: _send,
        ),
      ),
    );
  }
}

// Enhanced confirm nudge bottom sheet with editing capabilities
class _ConfirmNudgeSheet extends StatefulWidget {
  final NudgeSpec spec;
  const _ConfirmNudgeSheet({required this.spec});

  @override
  State<_ConfirmNudgeSheet> createState() => _ConfirmNudgeSheetState();
}

class _ConfirmNudgeSheetState extends State<_ConfirmNudgeSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _reminder;
  late int _targetCount;
  late String _category;
  late String _scheduleType;

  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = const [
    'Health', 'Fitness', 'Productivity', 'Personal'
  ];
  final List<String> _scheduleOptions = const [
    'times_per_day', 'daily'
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.spec.title);
    _description = TextEditingController(text: widget.spec.description);
    _reminder = TextEditingController(text: widget.spec.reminderText);
    _targetCount = widget.spec.targetCount;
    _category = widget.spec.category;
    _scheduleType = widget.spec.scheduleType;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _reminder.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final edited = NudgeSpec(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      targetCount: _targetCount,
      scheduleType: _scheduleType,
      reminderText: _reminder.text.trim(),
    );
    Navigator.of(context).pop(edited);
  }

  String _getScheduleDisplayName(String scheduleType) {
    switch (scheduleType) {
      case 'times_per_day':
        return 'Times per day';
      case 'daily':
        return 'Daily';
      default:
        return scheduleType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: bottomInset + 20, top: 12),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getCategoryIcon(_category),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review & Create Nudge',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Customize details before creating',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Form fields
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Stay Hydrated',
                    filled: true,
                    fillColor: AppTheme.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What exactly should happen?',
                    filled: true,
                    fillColor: AppTheme.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

                // Category and Schedule Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categories.contains(_category) ? _category : _categories.first,
                        items: _categories.map((c) => DropdownMenuItem(
                          value: c, 
                          child: Row(
                            children: [
                              Text(_getCategoryIcon(c), style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          )
                        )).toList(),
                        onChanged: (v) => setState(() => _category = v ?? _categories.first),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: AppTheme.backgroundGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _scheduleType,
                        items: _scheduleOptions.map((s) => DropdownMenuItem(
                          value: s, 
                          child: Text(_getScheduleDisplayName(s))
                        )).toList(),
                        onChanged: (v) => setState(() => _scheduleType = v ?? _scheduleOptions.first),
                        decoration: InputDecoration(
                          labelText: 'Schedule',
                          filled: true,
                          fillColor: AppTheme.backgroundGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target count
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Target per day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _targetCount = (_targetCount > 1) ? _targetCount - 1 : 1),
                        icon: const Icon(Icons.remove_circle_outline),
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_targetCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _targetCount += 1),
                        icon: const Icon(Icons.add_circle_outline),
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Nudge',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return '💧';
      case 'fitness':
        return '💪';
      case 'productivity':
        return '📋';
      case 'personal':
        return '✨';
      default:
        return '🎯';
    }
  }
}

// Welcome pane (when chat is empty)
class _WelcomePane extends StatelessWidget {
  const _WelcomePane({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onHistoryTap,
  });

  final TextEditingController controller;
  final Future<void> Function(String) onSend;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + name
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 40,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AI Behavioral Coach',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell me about a habit you\'d like to build, and I\'ll help you create tiny, sustainable nudges.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Suggestion chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _SuggestionChip('Drink more water', controller, onSend),
                    _SuggestionChip('Exercise daily', controller, onSend),
                    _SuggestionChip('Better sleep routine', controller, onSend),
                    _SuggestionChip('Connect with family', controller, onSend),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Input field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGray),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'What habit would you like to build?',
                            border: InputBorder.none,
                          ),
                          maxLines: 3,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: onSend,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) onSend(text);
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View chat history'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final Function(String) onSend;

  const _SuggestionChip(this.text, this.controller, this.onSend);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.text = text;
        onSend(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

// Chat pane (after first message)
class _ChatPane extends StatelessWidget {
  const _ChatPane({
    super.key,
    required this.messages,
    required this.isTyping,
    required this.controller,
    required this.scrollController,
    required this.onSend,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final TextEditingController controller;
  final ScrollController scrollController;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length + (isTyping ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (isTyping && index == messages.length) {
                return _TypingIndicator();
              }
              final message = messages[index];
              return _ChatBubble(message: message);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.cardWhite,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: AppTheme.backgroundGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        onSend(text);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      onSend(text);
                    }
                  },
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryPurple,
            child: const Icon(
              Icons.psychology_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser 
                  ? AppTheme.primaryPurple 
                  : AppTheme.cardWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: AppTheme.borderGray),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isUser ? Colors.white : AppTheme.textDark,
              ),
            ),
          ),
        ),
        
        if (isUser) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.textGray,
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> 
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryPurple,
          child: const Icon(
            Icons.psychology_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: AppTheme.borderGray),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final value = (_controller.value + delay) % 1.0;
                  final opacity = (0.4 + 0.6 * (0.5 + 0.5 * 
                      _sine(value * 2 * 3.14159))).clamp(0.0, 1.0);
                  
                  return Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.textGray.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  double _sine(double x) {
    // Simple sine approximation
    while (x > 3.14159) x -= 2 * 3.14159;
    while (x < -3.14159) x += 2 * 3.14159;
    
    if (x < 0) return -_sine(-x);
    
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }
}

// Data models
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime time;

  ChatMessage({
    required this.role, 
    required this.text, 
    required this.time,
  });
}

class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });
}

class NudgeSpec {
  final String title;
  final String description;
  final String category;
  final int targetCount;
  final String scheduleType;
  final String reminderText;

  NudgeSpec({
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.scheduleType,
    required this.reminderText,
  });
}

// Chat archive for storing conversations
class ChatArchive {
  static final List<ChatSession> _sessions = [];

  static void saveSessionFromMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final title = _deriveTitle(messages);
    _sessions.insert(0, ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      updatedAt: DateTime.now(),
      messages: List<ChatMessage>.from(messages),
    ));
  }

  static void autosaveFromMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final title = _deriveTitle(messages);
    if (_sessions.isEmpty) {
      saveSessionFromMessages(messages);
    } else {
      _sessions[0] = ChatSession(
        id: _sessions[0].id,
        title: title,
        updatedAt: DateTime.now(),
        messages: List<ChatMessage>.from(messages),
      );
    }
  }

  static List<ChatSession> all() => List.unmodifiable(_sessions);
  
  static void delete(String id) => _sessions.removeWhere((s) => s.id == id);

  static String _deriveTitle(List<ChatMessage> messages) {
    final firstUser = messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => messages.first,
    );
    final text = firstUser.text.trim();
    return text.length <= 40 ? text : '${text.substring(0, 40)}…';
  }
}