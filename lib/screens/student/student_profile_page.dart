import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sahabatbk/widgets/app_logo.dart';
import 'package:sahabatbk/screens/auth/login_page.dart';
import 'package:sahabatbk/providers/auth_provider.dart';
import 'package:sahabatbk/providers/user_provider.dart';
import 'package:sahabatbk/providers/auth_service.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() =>
      _StudentProfilePageState();
}

class _StudentProfilePageState
    extends ConsumerState<StudentProfilePage> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final firestore = ref.read(firestoreProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada pengguna yang login')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6E6),
      body: SafeArea(
        child: userDataAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            if (data == null) {
              return const Center(
                child: Text('Data profil tidak ditemukan'),
              );
            }

            final docRef =
                firestore.collection('users').doc(user.uid);

            final String nama = (data['nama'] ?? '').toString();
            final String email = (data['email'] ?? '').toString();
            final String nisn = (data['nisn'] ?? '').toString();
            final String kelas = (data['kelas'] ?? '').toString();
            final String role =
                (data['role'] ?? 'siswa').toString().toLowerCase();

            final int kelaseditcount =
                (data['kelaseditcount'] ?? 0) as int;

            final lastTs = data['lastkelaseditat'];
            final DateTime? lastkelaseditat =
                lastTs is Timestamp ? lastTs.toDate() : null;

            bool canEditKelas = _canEditKelas(
              kelaseditcount: kelaseditcount,
              lastkelaseditat: lastkelaseditat,
            );

            String avatarText() {
              final initial =
                  nama.isNotEmpty ? nama[0].toUpperCase() : '?';
              return role == 'guru'
                  ? 'G$initial'
                  : 'S$initial';
            }

            return Column(
              children: [
                const _ProfileHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor:
                                const Color(0xFF0F3A52),
                            child: Text(
                              avatarText(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nama.isEmpty ? '-' : nama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role == 'guru'
                                ? 'Guru'
                                : 'Siswa',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _infoField(
                              label: 'NISN', value: nisn),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _infoField(
                                  label: 'Kelas',
                                  value:
                                      kelas.isEmpty ? '-' : kelas,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: (_updating ||
                                        !canEditKelas)
                                    ? null
                                    : () {
                                        _changeKelas(
                                          docRef: docRef,
                                          currentKelas: kelas,
                                          currentCount:
                                              kelaseditcount,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF0F3A52),
                                ),
                                child: const Text(
                                  'Ubah',
                                  style:
                                      TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _kelasHintText(
                            canEdit: canEditKelas,
                            kelaseditcount: kelaseditcount,
                            lastkelaseditat: lastkelaseditat,
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updating
                                  ? null
                                  : _handleLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 14),
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authService = ref.read(authServiceProvider);
    await authService.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  bool _canEditKelas({
    required int kelaseditcount,
    required DateTime? lastkelaseditat,
  }) {
    if (kelaseditcount >= 2) return false;
    if (lastkelaseditat == null) return true;

    final nextAllowed = DateTime(
      lastkelaseditat.year + 1,
      lastkelaseditat.month,
      lastkelaseditat.day,
    );

    return DateTime.now().isAfter(nextAllowed);
  }

  Future<void> _changeKelas({
    required DocumentReference<Map<String, dynamic>> docRef,
    required String currentKelas,
    required int currentCount,
  }) async {
    final controller =
        TextEditingController(text: currentKelas);

    final newKelas = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Kelas'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Contoh: XI IPA 2'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newKelas == null || newKelas.isEmpty) return;

    setState(() => _updating = true);

    await docRef.update({
      'kelas': newKelas,
      'kelaseditcount': currentCount + 1,
      'lastkelaseditat': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelas berhasil diubah')),
      );
      setState(() => _updating = false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F3A52),
      child: Row(
        children: const [
          AppLogo(size: 26),
          SizedBox(width: 8),
          Text(
            'Sahabat BK - Profil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _infoField({required String label, required String value}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: value.isEmpty ? '-' : value,
          filled: true,
        ),
      ),
    ],
  );
}

Widget _kelasHintText({
  required bool canEdit,
  required int kelaseditcount,
  required DateTime? lastkelaseditat,
}) {
  if (!canEdit) {
    return const Text(
      'Kelas hanya dapat diubah maksimal 2 kali dengan jarak 12 bulan',
      style: TextStyle(fontSize: 11, color: Colors.red),
    );
  }
  return const Text(
    'Perubahan kelas maksimal 2 kali',
    style: TextStyle(fontSize: 11, color: Colors.grey),
  );
}
