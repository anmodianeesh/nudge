// lib/presentation/screens/nudges/widgets/personal_nudges_list.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/nudge_model.dart';
import '../../../../data/repositories/nudge_repository.dart';
import '../../../../data/services/supabase_service.dart';

class PersonalNudgesList extends StatefulWidget {
  const PersonalNudgesList({super.key});

  @override
  State<PersonalNudgesList> createState() => _PersonalNudgesListState();
}

class _PersonalNudgesListState extends State<PersonalNudgesList> {
  final _repo = NudgeRepository();

  String? _uid;
  Stream<List<Nudge>>? _stream;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _attachForCurrentUser(); // try immediately (covers cold start with session)
    // React to sign-in/sign-out so the list updates without hot restart.
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.session != null) {
        _attachForCurrentUser();
      } else {
        // signed out → clear stream
        setState(() {
          _uid = null;
          _stream = null;
        });
      }
    });
  }

  void _attachForCurrentUser() {
    final u = SupabaseService.client.auth.currentUser;
    if (u == null) return; // not signed in yet; we'll attach on auth event
    if (_uid == u.id && _stream != null) return; // already attached for this user

    setState(() {
      _uid = u.id;
      _stream = _repo.streamUserNudges(_uid!);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _editNudgeDialog(Nudge n) async {
    final titleCtrl = TextEditingController(text: n.title);
    final descCtrl = TextEditingController(text: n.description);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit nudge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.updateNudge(
        id: n.id, // this is your app_id value in DB
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not signed in yet or stream not ready → small loader.
    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Nudge>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
        }
        final items = snap.data ?? const <Nudge>[];
        if (items.isEmpty) {
          return const Center(child: Text('No personal nudges yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = items[i];
            return Dismissible(
              key: ValueKey(n.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete nudge?'),
                    content: Text('Delete "${n.title}"'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                return ok == true;
              },
              onDismissed: (_) async {
                await _repo.deleteNudge(n.id); // targets app_id in repo
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: ListTile(
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(n.description),
                  onTap: () => _editNudgeDialog(n),
                  leading: IconButton(
                    tooltip: 'Mark done',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _repo.markDone(id: n.id, newCountAsStreak: n.streak ?? 0),
                  ),
                  trailing: Switch(
                    value: n.isActive,
                    onChanged: (v) => _repo.toggleActive(n.id, v),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
