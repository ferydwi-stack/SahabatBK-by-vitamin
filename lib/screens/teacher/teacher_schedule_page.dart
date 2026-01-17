// lib/screens/teacher/teacher_schedule_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'teacher_common_widgets.dart';

class TeacherSchedulePage extends StatelessWidget {
  const TeacherSchedulePage({super.key});

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
    final jam = tanggal.hour.toString().padLeft(2, '0');
    final menit = tanggal.minute.toString().padLeft(2, '0');
    
    return '$hari $namaBulan $tahun, $jam:$menit';
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

  Future<void> _selesaikanKonseling(BuildContext context, String pengajuanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Konseling'),
        content: const Text('Apakah konseling sudah selesai? Status akan diubah menjadi "Selesai".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('pengajuan')
          .doc(pengajuanId)
          .update({
        'status': 'Selesai',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status konseling diubah menjadi Selesai'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
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
          TeacherHeader(title: 'Jadwal Konseling'),
          Expanded(
            child: Center(child: Text('Anda belum login')),
          ),
        ],
      );
    }

    return Column(
      children: [
        const TeacherHeader(title: 'Jadwal Konseling'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('pengajuan')
                .where('status', isEqualTo: 'Diterima')
                .where('guru_uid', isEqualTo: user.uid)
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

              return _buildScheduleList(context, snapshot);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text('Belum ada jadwal konseling'),
      );
    }

    // Filter hanya yang punya tanggal_jadwal dan sort
    final docsWithJadwal = snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tanggal_jadwal'] != null;
    }).toList()
      ..sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTs = aData['tanggal_jadwal'] as Timestamp?;
        final bTs = bData['tanggal_jadwal'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return aTs.compareTo(bTs); // ascending (terdekat dulu)
      });

    if (docsWithJadwal.isEmpty) {
      return const Center(
        child: Text('Belum ada jadwal konseling'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docsWithJadwal.length,
      itemBuilder: (context, index) {
        final doc = docsWithJadwal[index];
        final data = doc.data() as Map<String, dynamic>;
        final String nisn = (data['nisn'] ?? '').toString();
        final String topik = (data['topik'] ?? '').toString();
        final Timestamp? jadwalTs = data['tanggal_jadwal'] as Timestamp?;
        final DateTime? jadwal = jadwalTs?.toDate();

        return FutureBuilder<String>(
          future: _getNamaSiswa(nisn),
          builder: (context, snapshot) {
            final namaSiswa = snapshot.data ?? 'Siswa';
            
            final String? tempat = data['tempat']?.toString();
            final String? catatan = data['catatan_jadwal']?.toString();
            
            return TeacherCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, color: Color(0xFF0F3A52)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Konseling dengan $namaSiswa',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (jadwal != null)
                    teacherInfoRow('Waktu', _formatTanggal(jadwal)),
                  if (topik.isNotEmpty)
                    teacherInfoRow('Topik', topik),
                  if (tempat != null && tempat.isNotEmpty)
                    teacherInfoRow('Tempat', tempat),
                  if (catatan != null && catatan.isNotEmpty)
                    teacherInfoRow('Catatan', catatan),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _selesaikanKonseling(context, doc.id),
                        child: const Text('Selesaikan'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

