// lib/presentation/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repos/ai_repo.dart';
import '../../../data/repos/nudges_repo.dart';
import '../../../data/network/api_client.dart';
import '../../../data/models/nudge_spec.dart';
import '../../../data/models/simple_nudge.dart';
import '../../../data/storage/simple_nudges_storage.dart';
import '../../widgets/confirm_nudge_sheet.dart';
import 'chat_history_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../core/settings/user_settings.dart';



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

  // API clients
  late final ApiClient _apiClient;
  late final AiRepo _aiRepo;
  late final NudgesRepo _nudgesRepo;

  @override
  void initState() {
    super.initState();
    // Initialize API clients - using mock for now
    _apiClient = ApiClient(baseUrl: 'http://localhost:3000');
    _aiRepo = MockAiRepo(); // Mock for testing
    _nudgesRepo = MockNudgesRepo(); // Mock for testing
  }

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
      // Check if user wants to create a nudge
      if (_shouldCreateNudge(trimmed)) {
        await _maybeCreateNudgeFromText(trimmed);
      } else {
        // Regular chat response
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() {
          _messages.add(ChatMessage(
            role: MessageRole.assistant,
            text: _fakeCoachReply(trimmed),
            time: DateTime.now(),
          ));
        });
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
      // Wherever this is in _send(...)
ChatArchive.autosaveFromMessages(_messages);

// ⬇️ Add this line right below the autosave
await _maybeCreateNudgeFromText(trimmed);

      _scrollToBottom();
    }
  }

  bool _shouldCreateNudge(String text) {
    final lower = text.toLowerCase();
    return lower.contains('remind me') || 
           lower.contains('create nudge') ||
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

// Creates a nudge from the user text via AI, shows confirm, saves to server,
// then refreshes the UI state so it appears in Personal/My screens instantly.
Future<void> _maybeCreateNudgeFromText(String text) async {
  bool shouldCreate = false;

  try {
    if (text.trim().isEmpty) return;

    // If you already have a heuristic function, prefer it.
    if (mounted && (this as dynamic)._shouldCreateNudge != null) {
      final f = (this as dynamic)._shouldCreateNudge as bool Function(String);
      shouldCreate = f(text);
    } else {
      // Simple fallback heuristic
      final lower = text.toLowerCase();
      shouldCreate = lower.contains('remind me') ||
                     lower.contains('create nudge') ||
                     lower.contains('habit') ||
                     lower.contains('routine');
    }
  } catch (_) {
    // never block
  }

  if (!shouldCreate) return;

final tz = await UserSettings.getTimezone();

  try {
    // 1) Ask backend AI to turn text into a NudgeSpec
    final spec = await _aiRepo.suggestFromChat(text, tz);
    if (!mounted) return;

    // 2) Confirm with the user
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ConfirmNudgeSheet(
        spec: spec,
        onConfirm: (s) => _nudgesRepo.createFromSpec(s), // server save
      ),
    );

    // 3) If saved, refresh in-app state so it shows up immediately
    if (ok == true && mounted) {
      context.read<NudgesCubit>().loadWithAINudges();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Nudge saved'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ));
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Couldn’t create nudge: $e'),
        behavior: SnackBarBehavior.floating,
      ));
  }
}

Future<void> _createNudge(NudgeSpec spec) async {
  // 1) Save on server (your existing API)
  await _nudgesRepo.createFromSpec(spec);

  // 2) Persist locally and get the id we just created
  final newId = await SimpleNudgesStorage.addNudgeWithCategoryReturningId(
    
    spec,
    NudgeCategory.personal,
  );

  // 3) Reflect in UI state immediately so it appears in Personal/My Nudges
  if (mounted) {
    context.read<NudgesCubit>().addPersonalFromSpec(newId, spec);
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fakeCoachReply(String userText) {
    if (userText.toLowerCase().contains('water')) {
      return "Great start. One glass now, one after lunch. Want a reminder?";
    }
    if (userText.toLowerCase().contains('sleep')) {
      return "Try a 10-minute wind-down at 21:30. I can nudge you.";
    }
    if (userText.toLowerCase().contains('study')) {
      return "2-minute focus sprint: open the doc, add one bullet. I'll check back.";
    }
    if (userText.toLowerCase().contains('family')) {
      return "Family time is precious. What small step can strengthen those bonds?";
    }
    if (userText.toLowerCase().contains('friend')) {
      return "Friendship needs nurturing. A quick text or call can make someone's day.";
    }
    return "Got it. Let's turn this into a tiny step you can do today.";
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
        title: Text(empty ? 'New chat' : 'AI Coach'),
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
        duration: const Duration(milliseconds: 220),
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

/* -------------------- WELCOME (centered) -------------------- */

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
                const SizedBox(height: 8),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.cardWhite,
                  child: Icon(Icons.auto_awesome_rounded, size: 36, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                const Text('Nudge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 28),

                // Big prompt card
                Material(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, color: AppTheme.textGray),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: false,
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: onSend,
                            decoration: const InputDecoration(
                              hintText: 'Chat with Nudge...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Send',
                          onPressed: () {
                            final t = controller.text.trim();
                            if (t.isNotEmpty) onSend(t);
                          },
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Previous chats'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textGray),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------- CHAT (after first send) -------------------- */

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingLarge,
            ),
            itemCount: messages.length + (isTyping ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (isTyping && index == messages.length) return const _TypingDots();
              final m = messages[index];
              return _ChatBubble(message: m);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge, 8, AppConstants.paddingLarge, AppConstants.paddingLarge),
            child: _Composer(
              controller: controller,
              onSend: onSend,
              enabled: !isTyping,
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------- Reusable pieces -------------------- */

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend, required this.enabled});
  final TextEditingController controller;
  final Future<void> Function(String) onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1, maxLines: 5,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Message Nudge…',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSend(text);
                }
              },
            ),
          ),
          IconButton(
            tooltip: 'Send',
            onPressed: enabled && controller.text.trim().isNotEmpty
                ? () => onSend(controller.text) : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryPurple,
            child: Icon(Icons.psychology_rounded, size: 16, color: Colors.white),
          ),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryBlue.withOpacity(0.10) : AppTheme.cardWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(color: AppTheme.borderGray),
            ),
            child: Text(message.text, style: const TextStyle(height: 1.35)),
          ),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser)
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.textDark,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}
class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryPurple,
          child: Icon(Icons.psychology_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderGray),
          ),
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, __) {
              final v = (t) => (1 + 0.5 * (1 + MathUtils.sin(2 * 3.1415 * (t)))) / 2;
              final t = _ac.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final scale = v((t + i / 3) % 1);
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                    child: Transform.scale(scale: 0.8 + 0.25 * scale, child: const _Dot()),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 6, height: 6,
      child: DecoratedBox(decoration: BoxDecoration(color: AppTheme.textGray, shape: BoxShape.circle)),
    );
  }
}

/* -------------------- Mock Classes for Testing -------------------- */

class MockAiRepo implements AiRepo {
  @override
  Future<NudgeSpec> suggestFromChat(String userInput, String tz) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate network delay
    
    // Generate different nudges based on input
    if (userInput.toLowerCase().contains('water')) {
      return NudgeSpec(
        title: "Drink more water",
        microStep: "Fill and finish one glass",
        tone: "friendly",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=11;BYMINUTE=0",
        reminderCopy: "Hydration time! 💧",
      );
    } else if (userInput.toLowerCase().contains('sleep')) {
      return NudgeSpec(
        title: "Better sleep routine",
        microStep: "Put phone on charger in hallway",
        tone: "gentle",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=21;BYMINUTE=30",
        reminderCopy: "Wind-down time 🌙",
      );
    } else if (userInput.toLowerCase().contains('exercise')) {
      return NudgeSpec(
        title: "Daily movement",
        microStep: "Do 10 jumping jacks",
        tone: "motivational",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=8;BYMINUTE=0",
        reminderCopy: "Let's get moving! 💪",
      );
    } else if (userInput.toLowerCase().contains('family')) {
      return NudgeSpec(
        title: "Connect with family",
        microStep: "Send one text to family member",
        tone: "warm",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=18;BYMINUTE=0",
        reminderCopy: "Family time! ❤️",
      );
    } else if (userInput.toLowerCase().contains('friend')) {
      return NudgeSpec(
        title: "Stay connected with friends",
        microStep: "Send a quick message to a friend",
        tone: "friendly",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=19;BYMINUTE=0",
        reminderCopy: "Friendship check-in! 👋",
      );
    } else if (userInput.toLowerCase().contains('work')) {
      return NudgeSpec(
        title: "Work productivity",
        microStep: "Review tomorrow's priorities",
        tone: "professional",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=17;BYMINUTE=0",
        reminderCopy: "Quick planning session 📋",
      );
    } else {
      return NudgeSpec(
        title: "Daily habit",
        microStep: "Take one small action",
        tone: "friendly",
        channels: const ["push"],
        tz: tz,
        rrule: "FREQ=DAILY;BYHOUR=12;BYMINUTE=0",
        reminderCopy: "Time for your daily habit! ✨",
      );
    }
  }
}

class MockNudgesRepo implements NudgesRepo {
  @override
  Future<String> createFromSpec(NudgeSpec spec) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Determine category based on content
    final category = _determineCategory(spec.title + " " + spec.microStep);
    
    // Save with category and AI flag, and get the new nudge ID
    final newId = await SimpleNudgesStorage.addNudgeWithCategoryReturningId(spec, category);
    print('Saved AI nudge: ${spec.title} in ${category.name} category');
    return newId;
  }
  
  NudgeCategory _determineCategory(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('family') || lower.contains('parent') || lower.contains('kid') || lower.contains('mom') || lower.contains('dad')) {
      return NudgeCategory.family;
    }
    if (lower.contains('friend') || lower.contains('social') || lower.contains('together') || lower.contains('connect')) {
      return NudgeCategory.friends;
    }
    if (lower.contains('work') || lower.contains('meeting') || lower.contains('project') || lower.contains('office') || lower.contains('productivity')) {
      return NudgeCategory.work;
    }
    return NudgeCategory.personal;
  }
}

/* -------------------- Lightweight models & archive -------------------- */

enum MessageRole { user, assistant }
class ChatMessage {
  final MessageRole role; final String text; final DateTime time;
  ChatMessage({required this.role, required this.text, required this.time});
}
class ChatSession {
  final String id; final String title; final DateTime updatedAt; final List<ChatMessage> messages;
  ChatSession({required this.id, required this.title, required this.updatedAt, required this.messages});
}

class ChatArchive {
  static final List<ChatSession> _sessions = [];
  static void saveSessionFromMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final title = _deriveTitle(messages);
    _sessions.insert(0, ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, updatedAt: DateTime.now(),
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
        id: _sessions[0].id, title: title, updatedAt: DateTime.now(),
        messages: List<ChatMessage>.from(messages),
      );
    }
  }
  static List<ChatSession> all() => List.unmodifiable(_sessions);
  static void delete(String id) => _sessions.removeWhere((s) => s.id == id);
  static String _deriveTitle(List<ChatMessage> messages) {
    final firstUser = messages.firstWhere((m) => m.role == MessageRole.user, orElse: () => messages.first);
    final t = firstUser.text.trim();
    return t.length <= 40 ? t : '${t.substring(0, 40)}…';
  }
}

class MathUtils {
  static double sin(double x) => _sinApprox(x);
  static double _sinApprox(double x) {
    const pi = 3.1415926535897932;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;
    final y = (16 * x * (pi - x)) / (5 * pi * pi - 4 * x * (pi - x));
    return y.clamp(-1.0, 1.0);
  }
}