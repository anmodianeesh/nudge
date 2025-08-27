import 'package:flutter/material.dart';
import '../../../data/models/nudge_model.dart';

class NudgeCard extends StatelessWidget {
  final Nudge nudge;

  const NudgeCard({super.key, required this.nudge});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(nudge.title),
        subtitle: Text(nudge.description),
      ),
    );
  }
}
