// lib/presentation/screens/nudges/my_nudges_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/premade_nudge.dart';
import '../../../data/storage/my_nudges_storage.dart';

class MyNudgesScreen extends StatefulWidget {
  const MyNudgesScreen({super.key});

  @override
  State<MyNudgesScreen> createState() => _MyNudgesScreenState();
}

class _MyNudgesScreenState extends State<MyNudgesScreen> {
  late Future<List<PremadeNudge>> _future;

  @override
  void initState() {
    super.initState();
    _future = MyNudgesStorage.loadAll();
  }

  Future<void> _refresh() async {
    final items = await MyNudgesStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _future = Future.value(items);
    });
  }

  Future<void> _addCustom() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Custom Nudge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (title.isEmpty || desc.isEmpty) return;
              await MyNudgesStorage.addCustom(title: title, description: desc);
              if (mounted) Navigator.pop(ctx);
              await _refresh();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom nudge added')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('My Nudges'),
        backgroundColor: AppTheme.cardWhite,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustom,
        label: const Text('Add custom'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PremadeNudge>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await MyNudgesStorage.remove(n.id);
                    await _refresh();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed "${n.title}"')),
                    );
                  },
                  child: ListTile(
                    tileColor: AppTheme.cardWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(n.description),
                    trailing: n.isCustom
                        ? const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.edit_note, color: AppTheme.textLight),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'No nudges yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            SizedBox(height: 8),
            Text(
              'Add from the library or create your own.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
