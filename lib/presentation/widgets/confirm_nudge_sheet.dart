// lib/presentation/widgets/confirm_nudge_sheet.dart
//
// Bottom sheet to preview an AI/premade NudgeSpec and save it.
// Usage:
// final ok = await showModalBottomSheet<bool>(
//   context: context,
//   isScrollControlled: true,
//   builder: (_) => ConfirmNudgeSheet(
//     spec: aiSpec,
//     onConfirm: (s) => context.read<NudgesRepo>().createFromSpec(s),
//   ),
// );

import 'package:flutter/material.dart';
import '../../data/models/nudge_spec.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ConfirmNudgeSheet extends StatelessWidget {
  final NudgeSpec spec;
  final Future<void> Function(NudgeSpec spec) onConfirm;

  const ConfirmNudgeSheet({
    super.key,
    required this.spec,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final schedule = _prettySchedule(spec.rrule, spec.tz);
    final channels = spec.channels.join(', ');

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.paddingLarge,
          right: AppConstants.paddingLarge,
          bottom: AppConstants.paddingLarge + MediaQuery.of(context).viewInsets.bottom,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Card
            Material(
              color: AppTheme.cardWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.borderGray),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.textDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(spec.title,
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  )),
                              const SizedBox(height: 4),
                              Text(spec.microStep,
                                  style: tt.bodyMedium?.copyWith(
                                    color: AppTheme.textGray,
                                    height: 1.35,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      title: schedule,
                      subtitle: spec.tz.replaceAll('_', ' '),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.notifications_active_rounded,
                      title: 'Channel: $channels',
                      subtitle: 'Tone: ${_capitalize(spec.tone)}',
                    ),

                    if (spec.reminderCopy.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.chat_bubble_rounded,
                        title: 'Reminder copy',
                        subtitle: '“${spec.reminderCopy}”',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderGray),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 1.5,
                      shadowColor: cs.primary.withOpacity(0.35),
                    ),
                    onPressed: () async {
                      try {
                        await onConfirm(spec);
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Couldn’t save nudge: $e'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save & Start'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- Pieces ----------------- */

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.textGray),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/* ----------------- Helpers ----------------- */

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _prettySchedule(String rrule, String tz) {
  // Minimal pretty printer for things like:
  // FREQ=DAILY;BYHOUR=20;BYMINUTE=0  ->  Daily at 20:00
  final parts = {
    for (final p in rrule.split(';'))
      if (p.contains('='))
        p.split('=')[0].toUpperCase(): p.split('=')[1]
  };

  final freq = (parts['FREQ'] ?? 'DAILY').toUpperCase();
  final byHour = parts['BYHOUR'];
  final byMin = parts['BYMINUTE'] ?? '0';

  String time = '';
  if (byHour != null) {
    final h = int.tryParse(byHour) ?? 0;
    final m = int.tryParse(byMin) ?? 0;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    time = ' at $hh:$mm';
  }

  switch (freq) {
    case 'DAILY':
      return 'Daily$time';
    case 'WEEKLY':
      final byDay = parts['BYDAY'] ?? '';
      return 'Weekly ($byDay)$time';
    case 'MONTHLY':
      final byMonthDay = parts['BYMONTHDAY'] ?? '';
      return 'Monthly${byMonthDay.isNotEmpty ? " (day $byMonthDay)" : ""}$time';
    default:
      return '$freq$time';
  }
}
