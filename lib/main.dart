import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nudge/presentation/screens/splash/splash_screen.dart';
import 'business_logic/cubits/nudges_cubit.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NudgesCubit()..loadNudges(),
      child: MaterialApp(
        title: 'Nudge App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor: AppTheme.backgroundGray,
          fontFamily: 'SF Pro Display', // or your preferred font
        ),
        home: const HomeScreen(), //changed temporarily to home for fast testing. default should be SplashScreen
      ),
    );
  }
}