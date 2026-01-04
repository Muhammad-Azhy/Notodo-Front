import 'package:flutter/material.dart';
import 'package:front/screens/login_page.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

import 'screens/home_page.dart';
import 'screens/references_page.dart';
import 'screens/tasks_page.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Notodo',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const LoginPage(),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static final List<Map<String, dynamic>> dummyProblems = [
    {
      "title": "Sample Problem",
      "subtitle": "Dummy tasks for testing",
      "tasks": [
        {"title": "Task 1", "done": false},
        {"title": "Task 2", "done": false},
        {"title": "Task 3", "done": false},
        {"title": "Task 4", "done": false},
        {"title": "Task 5", "done": false},
        {"title": "Task 6", "done": true},
        {"title": "Task 7", "done": true},
        {"title": "Task 8", "done": true},
        {"title": "Task 9", "done": true},
        {"title": "Task 10", "done": true},
      ],
      "references": [],
    },
  ];

  static List<Widget> _pages = [
    HomePage(), // pass dummyProblems here
    ReferencesPage(), // pass dummyProblems here too
    TasksPage(), // and here
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Problems'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file),
            label: 'References',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Tasks'),
        ],
      ),
    );
  }
}
