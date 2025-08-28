// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'business_logic/cubits/nudges_cubit.dart';
import 'presentation/navigation/root_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NudgeApp());
}

class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NudgesCubit()..loadInitial(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nudge',
        theme: AppTheme.lightTheme,
        home: const RootNav(),
      ),
    );
  }
}

