import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'screens/planner_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Planner Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const PlannerScreen(),
    );
  }
}
