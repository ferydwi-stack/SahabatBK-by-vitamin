// lib/screens/student/student_home_page.dart
import 'package:flutter/material.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'student_request_page.dart';
import 'student_status_page.dart';
import 'student_history_page.dart';
import 'student_profile_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;

  final _pages = const [
    StudentRequestPage(),
    StudentStatusPage(),
    StudentHistoryPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_comment_outlined),
            label: 'Ajukan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
