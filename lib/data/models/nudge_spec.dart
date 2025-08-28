// lib/data/models/nudge_spec.dart
//
// Canonical spec for every nudge (premade or AI-generated).
// Keep it small for the first slice (time-based push), but flexible enough
// to add usage/location triggers and channels later.

import 'dart:convert';

/// Lightweight, validated config for a nudge.
/// First slice: time-based reminders via RRULE in a timezone.
class NudgeSpec {
  final String title;          // e.g. "Drink one glass of water"
  final String microStep;      // e.g. "Fill and finish one glass"
  final String tone;           // 'friendly' | 'motivational' | 'firm' | ...
  final List<String> channels; // e.g. ['push'] (later: 'whatsapp', 'email')
  final String tz;             // IANA tz, e.g. 'Europe/Madrid'
  final String rrule;          // e.g. 'FREQ=DAILY;BYHOUR=20;BYMINUTE=0'
  final String reminderCopy;   // short message shown in the notification

  const NudgeSpec({
    required this.title,
    required this.microStep,
    required this.tone,
    required this.channels,
    required this.tz,
    required this.rrule,
    required this.reminderCopy,
  });

  /// Parse from trusted JSON (already a map).
  factory NudgeSpec.fromJson(Map<String, dynamic> j) {
    final spec = NudgeSpec(
      title: _asString(j, 'title'),
      microStep: _asString(j, 'micro_step'),
      tone: _asString(j, 'tone', or: 'friendly'),
      channels: _asStrings(j, 'channel', or: const ['push']),
      tz: _asString(j, 'tz'),
      rrule: _asString(j, 'rrule'),
      reminderCopy: _asString(j, 'reminder_copy', or: ''),
    );
    spec.validate(); // throws FormatException with a readable message
    return spec;
  }

  /// Parse directly from an AI/raw JSON string. Throws FormatException on error.
  factory NudgeSpec.fromAiJsonString(String jsonStr) {
    final dynamic decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI output must be a JSON object');
    }
    return NudgeSpec.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'micro_step': microStep,
        'tone': tone,
        'channel': channels,
        'tz': tz,
        'rrule': rrule,
        'reminder_copy': reminderCopy,
      };

  NudgeSpec copyWith({
    String? title,
    String? microStep,
    String? tone,
    List<String>? channels,
    String? tz,
    String? rrule,
    String? reminderCopy,
  }) {
    return NudgeSpec(
      title: title ?? this.title,
      microStep: microStep ?? this.microStep,
      tone: tone ?? this.tone,
      channels: channels ?? this.channels,
      tz: tz ?? this.tz,
      rrule: rrule ?? this.rrule,
      reminderCopy: reminderCopy ?? this.reminderCopy,
    );
  }

  /// Basic guard-rails so we fail early with clear errors.
  void validate() {
    String fail(String m) => throw FormatException('Invalid NudgeSpec: $m');

    if (title.trim().isEmpty) fail('title is empty');
    if (microStep.trim().isEmpty) fail('micro_step is empty');

    if (channels.isEmpty) fail('channel must have at least one entry');
    for (final c in channels) {
      final ok = {'push', 'whatsapp', 'email', 'slack'}.contains(c);
      if (!ok) fail('unsupported channel "$c"');
    }

    if (!_looksLikeTz(tz)) fail('tz "$tz" is not a valid IANA-like timezone');
    if (!_looksLikeRRule(rrule)) {
      fail('rrule "$rrule" is missing FREQ or time components');
    }
  }

  // ---- Helpers -------------------------------------------------------------

  static String _asString(Map<String, dynamic> j, String k, {String or = ''}) {
    final v = j[k];
    if (v == null) {
      if (or.isNotEmpty) return or;
      throw FormatException('Missing "$k"');
    }
    if (v is String) return v;
    throw FormatException('Field "$k" must be a string');
  }

  static List<String> _asStrings(Map<String, dynamic> j, String k,
      {List<String> or = const []}) {
    final v = j[k];
    if (v == null) return or;
    if (v is List) {
      return v.map((e) => e.toString()).toList(growable: false);
    }
    throw FormatException('Field "$k" must be an array of strings');
  }

  static bool _looksLikeTz(String s) {
    // Minimal sanity check (e.g., Europe/Madrid, America/New_York)
    return RegExp(r'^[A-Za-z]+\/[A-Za-z_]+$').hasMatch(s);
  }

  static bool _looksLikeRRule(String s) {
    // Minimal sanity: must include FREQ and typically some BY* or INTERVAL.
    final up = s.toUpperCase();
    final hasFreq = up.contains('FREQ=');
    final hasAnyTime =
        up.contains('BYHOUR=') || up.contains('BYMINUTE=') || up.contains('BYDAY=');
    return hasFreq && hasAnyTime;
  }
}
