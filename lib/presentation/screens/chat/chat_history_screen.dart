import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'chat_screen.dart' show ChatArchive, ChatSession;

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sessions = ChatArchive.all().where((s) {
      if (_query.isEmpty) return true;
      return s.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        title: const Text('Previous chats'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              8,
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search conversations…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    itemBuilder: (_, i) {
                      final s = sessions[i];
                      return Dismissible(
                        key: ValueKey(s.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() {
                            ChatArchive.delete(s.id);
                          });
                        },
                        child: ListTile(
                          tileColor: AppTheme.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.borderGray),
                          ),
                          title: Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            _prettyTime(s.updatedAt),
                            style: const TextStyle(color: AppTheme.textGray),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop<ChatSession>(s),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: sessions.length,
                  ),
          ),
        ],
      ),
    );
  }

  String _prettyTime(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today $h:$m';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_rounded, size: 64, color: AppTheme.textLight),
            SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Your chats will appear here so you can revisit or resume them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
