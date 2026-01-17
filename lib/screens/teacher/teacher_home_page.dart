// lib/screens/teacher/teacher_home_page.dart
import 'package:flutter/material.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'teacher_incoming_requests_page.dart';
import 'teacher_schedule_page.dart';
import 'teacher_notes_page.dart';
import 'teacher_profile_page.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentIndex = 0;

  final _pages = const [
    TeacherIncomingRequestsPage(),
    TeacherSchedulePage(),
    TeacherNotesPage(),
    TeacherProfilePage(),
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
            icon: Icon(Icons.inbox_outlined),
            label: 'Pengajuan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Catatan',
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
