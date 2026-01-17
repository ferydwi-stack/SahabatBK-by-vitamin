// lib/screens/teacher/teacher_notes_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'teacher_common_widgets.dart';

class TeacherNotesPage extends StatelessWidget {
  const TeacherNotesPage({super.key});

  String _formatTanggal(DateTime tanggal) {
    final bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    
    final hari = tanggal.day.toString().padLeft(2, '0');
    final namaBulan = bulan[tanggal.month - 1];
    final tahun = tanggal.year;
    
    return '$hari $namaBulan $tahun';
  }

  Future<String> _getNamaSiswa(String nisn) async {
    if (nisn.isEmpty) return 'Siswa';
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('nisn', isEqualTo: nisn)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return (data['nama'] ?? 'Siswa').toString();
      }
    } catch (e) {
      // Error getting nama
    }
    
    return 'Siswa';
  }

  Future<void> _simpanCatatan(
  BuildContext context,
  String pengajuanId,
  String catatan,
) async {
  if (catatan.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Masukkan catatan terlebih dahulu')),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('catatan')
        .doc(pengajuanId)
        .set({
      'pengajuan_id': pengajuanId,
      'guru_uid': user.uid,
      'catatan': catatan.trim(),
      'tanggal': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Column(
        children: [
          TeacherHeader(title: 'Catatan Konseling'),
          Expanded(
            child: Center(child: Text('Anda belum login')),
          ),
        ],
      );
    }

    return Column(
      children: [
        const TeacherHeader(title: 'Catatan Konseling'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('pengajuan')
                .where('guru_uid', isEqualTo: user.uid)
                .where('status', isEqualTo: 'Selesai')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Belum ada pengajuan yang selesai'),
                );
              }

              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTs = aData['tanggal_jadwal'] as Timestamp?;
                  final bTs = bData['tanggal_jadwal'] as Timestamp?;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs); // descending (terbaru dulu)
                });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _NoteCard(
                    pengajuanId: doc.id,
                    data: data,
                    onSaveCatatan: _simpanCatatan,
                    getNamaSiswa: _getNamaSiswa,
                    formatTanggal: _formatTanggal,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    required this.pengajuanId,
    required this.data,
    required this.onSaveCatatan,
    required this.getNamaSiswa,
    required this.formatTanggal,
  });

  final String pengajuanId;
  final Map<String, dynamic> data;
  final Future<void> Function(BuildContext, String, String) onSaveCatatan;
  final Future<String> Function(String) getNamaSiswa;
  final String Function(DateTime) formatTanggal;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  final _catatanController = TextEditingController();
  bool _isExpanded = false;
  bool _loadingCatatan = true;
  String? _existingCatatan;

  @override
  void initState() {
    super.initState();
    _loadCatatan();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

Future<void> _loadCatatan() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('catatan')
        .doc(widget.pengajuanId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['guru_uid'] == user.uid) {
        _existingCatatan = data['catatan']?.toString() ?? '';
        _catatanController.text = _existingCatatan!;
      }
    }
  } catch (e) {
    // silent fail
  } finally {
    if (mounted) {
      setState(() => _loadingCatatan = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final String nisn = (widget.data['nisn'] ?? '').toString();
    final String topik = (widget.data['topik'] ?? '').toString();
    final Timestamp? jadwalTs = widget.data['tanggal_jadwal'] as Timestamp?;
    final DateTime? jadwal = jadwalTs?.toDate();

    return FutureBuilder<String>(
      future: widget.getNamaSiswa(nisn),
      builder: (context, snapshot) {
        final namaSiswa = snapshot.data ?? 'Siswa';

        return TeacherCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaSiswa,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (topik.isNotEmpty)
                            Text(
                              'Topik: $topik',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          if (jadwal != null)
                            Text(
                              'Jadwal: ${widget.formatTanggal(jadwal)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const Divider(height: 16),
                if (_loadingCatatan)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  const Text(
                    'Catatan Konseling',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanController,
                    maxLines: 4,
                    decoration: teacherInputDecoration().copyWith(
                      hintText: 'Tulis catatan hasil konseling...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => widget.onSaveCatatan(
                        context,
                        widget.pengajuanId,
                        _catatanController.text,
                      ),
                      child: const Text(
                        'Simpan Catatan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

