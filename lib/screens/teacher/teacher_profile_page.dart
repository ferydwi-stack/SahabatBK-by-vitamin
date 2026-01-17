import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sahabatbk/screens/auth/login_page.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'teacher_common_widgets.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() =>
      _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final TextEditingController _jabatanController =
      TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _jabatanController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _autoSaveJabatan(String uid, String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(
        {'jabatan': value.trim()},
        SetOptions(merge: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada pengguna yang login')),
      );
    }

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Column(
      children: [
        const TeacherHeader(title: 'Profil Guru'),
        Expanded(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: docRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text('Data profil tidak ditemukan'),
                );
              }

              final data = snapshot.data!.data()!;

              final String nama = (data['nama'] ?? '').toString();
              final String email = (data['email'] ?? '').toString();
              final String nip = (data['nip'] ?? '').toString();
              final String jabatan =
                  (data['jabatan'] ?? '').toString();

              _jabatanController.text = jabatan;

              String avatarText() {
                final initial =
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?';
                return 'G$initial';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TeacherCardContainer(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      // ===== AVATAR =====
                      CircleAvatar(
                        radius: 38,
                        backgroundColor:
                            AppColors.secondary,
                        child: Text(
                          avatarText(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ===== TITLE JABATAN =====
                      Text(
                        jabatan.isNotEmpty ? jabatan : 'Guru',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _profileFieldReadOnly(
                        label: 'NIP',
                        value: nip.isEmpty ? '-' : nip,
                      ),
                      const SizedBox(height: 10),

                      _profileFieldReadOnly(
                        label: 'Nama',
                        value: nama.isEmpty ? '-' : nama,
                      ),
                      const SizedBox(height: 10),

                      _profileFieldReadOnly(
                        label: 'Email',
                        value: email,
                      ),
                      const SizedBox(height: 16),

                      // ===== JABATAN (EDITABLE) =====
                      _profileFieldEditable(
                        label: 'Jabatan ',
                        controller: _jabatanController,
                        onChanged: (v) =>
                            _autoSaveJabatan(user.uid, v),
                      ),

                      const SizedBox(height: 30),

                      // ===== LOGOUT =====
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _handleLogout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content:
            const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

/* ===================== WIDGET FIELD ===================== */

Widget _profileFieldReadOnly({
  required String label,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: value,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ],
  );
}

Widget _profileFieldEditable({
  required String label,
  required TextEditingController controller,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Contoh: Guru BK',
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onChanged: onChanged,
      ),
    ],
  );
}
