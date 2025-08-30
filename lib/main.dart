// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'business_logic/cubits/nudges_cubit.dart';

import 'presentation/navigation/root_nav.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

const bool kForceOnboarding = true; // set to false when you want auto-login again

// RestartWidget to simulate hot restart
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restart() {
    setState(() {
      _key = UniqueKey(); // forces the entire subtree to rebuild from scratch
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gxrdowsojofpocspqoje.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4cmRvd3Nvam9mcG9jc3Bxb2plIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0MjI5NDcsImV4cCI6MjA3MTk5ODk0N30.msW84Kpiowvk3mifOJaqfazfPxSS_N1_rdoW7Z0koNs',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
  );
  runApp(
    RestartWidget(
      child: BlocProvider(
        create: (_) => NudgesCubit()..loadInitial(), // local/demo data first
        child: const NudgeApp(),
      ),
    ),
  );
}

class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nudge',
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({super.key});
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  RealtimeChannel? _nudgesChannel;
  bool _kickedInitialLoadOnce = false;

  @override
  void initState() {
    super.initState();

    // Auth changes → load + subscribe
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (!mounted) return;

      if (session != null) {
        context.read<NudgesCubit>().loadFromCloud();
        _subscribeNudgesRealtime();
      } else {
        _teardownRealtime();
        _kickedInitialLoadOnce = false; // allow next sign-in to kick again
      }
    });

    // Cold start with existing session?
    if (SupabaseService.client.auth.currentSession != null) {
      context.read<NudgesCubit>().loadFromCloud();
      _subscribeNudgesRealtime();
    }
  }

  void _subscribeNudgesRealtime() {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null || _nudgesChannel != null) return;

    _nudgesChannel = SupabaseService.client
        .channel('nudges-user-$uid-authgate')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'nudges',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) {
            if (mounted) {
              context.read<NudgesCubit>().loadFromCloud();
            }
          },
        )
        .subscribe();
  }

  void _teardownRealtime() {
    if (_nudgesChannel != null) {
      SupabaseService.client.removeChannel(_nudgesChannel!);
      _nudgesChannel = null;
    }
  }

  @override
  void dispose() {
    _teardownRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SupabaseService.client.auth.currentSession;

    if (session != null) {
      // If we got here before init listeners fired, kick one guaranteed load
      if (!_kickedInitialLoadOnce) {
        _kickedInitialLoadOnce = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<NudgesCubit>().loadFromCloud();
        });
      }
      return const RootNav();
    }

    return const OnboardingScreen();
  }
}