// lib/screens/student/student_request_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahabatbk/providers/auth_provider.dart';
import 'package:sahabatbk/providers/user_provider.dart';
import 'student_common_widgets.dart';

class StudentRequestPage extends ConsumerStatefulWidget {
  const StudentRequestPage({super.key});

  @override
  ConsumerState<StudentRequestPage> createState() => _StudentRequestPageState();
}

class _StudentRequestPageState extends ConsumerState<StudentRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTopik;
  final _deskripsiController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTopik == null || _selectedTopik!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih topik terlebih dahulu')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final firestore = ref.read(firestoreProvider);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Ambil data user langsung dari Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data pengguna tidak ditemukan di Firestore')),
          );
        }
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data pengguna tidak ditemukan')),
          );
        }
        return;
      }

      final String nisn = (userData['nisn'] ?? '').toString();
      if (nisn.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NISN tidak ditemukan di profil')),
          );
        }
        return;
      }

      // Simpan pengajuan ke Firestore
      await firestore.collection('pengajuan').add({
        'topik': _selectedTopik,
        'deskripsi': _deskripsiController.text.trim(),
        'nisn': nisn,
        'nip': '', // Kosong untuk siswa
        'status': '', // Status kosong saat pertama kali diajukan
        'tanggal_pengajuan': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _selectedTopik = null;
        });
        _deskripsiController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pengajuan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StudentHeader(title: 'Mengajukan Konseling'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StudentCardContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Isi form',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Topik'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      decoration: studentInputDecoration(),
                      value: _selectedTopik,
                      items: const [
                        DropdownMenuItem(
                            value: 'Pembullyan', child: Text('Pembullyan')),
                        DropdownMenuItem(
                            value: 'Keluarga', child: Text('Keluarga')),
                        DropdownMenuItem(
                            value: 'Akademik', child: Text('Akademik')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTopik = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih topik terlebih dahulu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Deskripsi'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: studentInputDecoration().copyWith(
                        hintText: 'Masukkan deskripsi',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Masukkan deskripsi terlebih dahulu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3A52),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        onPressed: _isSubmitting ? null : _submitPengajuan,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Kirim',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
