import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/visitor_provider.dart';
import 'screens/app_shell.dart';
import 'services/visitor_api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => VisitorProvider(VisitorApiService())..loadVisitors(),
      child: const VisitorManagementApp(),
    ),
  );
}

class VisitorManagementApp extends StatelessWidget {
  const VisitorManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visitor Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
