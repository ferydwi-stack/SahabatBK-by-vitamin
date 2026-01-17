// lib/screens/student/student_status_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sahabatbk/providers/auth_provider.dart';
import 'package:sahabatbk/providers/user_provider.dart';
import 'student_common_widgets.dart';

class StudentStatusPage extends ConsumerWidget {
  const StudentStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firestore = ref.watch(firestoreProvider);

    if (user == null) {
      return Column(
        children: [
          const StudentHeader(title: 'Status Pengajuan Konseling'),
          const Expanded(
            child: Center(child: Text('Anda belum login')),
          ),
        ],
      );
    }

    return Column(
      children: [
        const StudentHeader(title: 'Status Pengajuan Konseling'),
        Expanded(
          child: FutureBuilder<DocumentSnapshot>(
            future: firestore.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${userSnapshot.error}'),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(
                  child: Text('Data pengguna tidak ditemukan'),
                );
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData == null) {
                return const Center(
                  child: Text('Data pengguna tidak ditemukan'),
                );
              }

              final String nisn = (userData['nisn'] ?? '').toString();
              if (nisn.isEmpty) {
                return const Center(
                  child: Text('NISN tidak ditemukan di profil'),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('pengajuan')
                    .where('nisn', isEqualTo: nisn)
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
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        StudentCardContainer(
                          child: Center(
                            child: Text('Belum ada pengajuan'),
                          ),
                        ),
                      ],
                    );
                  }

                  // Sort by tanggal_pengajuan descending (client-side)
                  final sortedDocs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTs = aData['tanggal_pengajuan'] as Timestamp?;
                      final bTs = bData['tanggal_pengajuan'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs); // descending
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      final doc = sortedDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String pengajuanId = doc.id;

                      final String topik = (data['topik'] ?? '').toString();
                      final String deskripsi = (data['deskripsi'] ?? '').toString();
                      final String status = (data['status'] ?? '').toString();
                      final String guruUid = (data['guru_uid'] ?? '').toString();
                      final String tempat = (data['tempat'] ?? '').toString();
                      final String catatanJadwal = (data['catatan_jadwal'] ?? '').toString();
                      final Timestamp? tanggalTs = data['tanggal_pengajuan'] as Timestamp?;
                      final DateTime? tanggal = tanggalTs?.toDate();
                      final Timestamp? jadwalTs = data['tanggal_jadwal'] as Timestamp?;
                      final DateTime? jadwal = jadwalTs?.toDate();

                      return StudentCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topik.isEmpty ? 'Tanpa Topik' : topik,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.isEmpty
                                        ? Colors.orange.withOpacity(0.2)
                                        : status.toLowerCase() == 'diterima'
                                            ? Colors.green.withOpacity(0.2)
                                            : status.toLowerCase() == 'ditolak'
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.isEmpty ? 'Menunggu' : status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: status.isEmpty
                                          ? Colors.orange.shade700
                                          : status.toLowerCase() == 'diterima'
                                              ? Colors.green.shade700
                                              : status.toLowerCase() == 'ditolak'
                                                  ? Colors.red.shade700
                                                  : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (tanggal != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tanggal Pengajuan: ${_formatTanggal(tanggal)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            // Tampilkan info jadwal jika status Diterima atau Selesai
                            if ((status.toLowerCase() == 'diterima' || status.toLowerCase() == 'selesai') && guruUid.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              FutureBuilder<DocumentSnapshot>(
                                future: firestore.collection('users').doc(guruUid).get(),
                                builder: (context, guruSnapshot) {
                                  String namaGuru = 'Guru BK';
                                  if (guruSnapshot.hasData && guruSnapshot.data!.exists) {
                                    final guruData = guruSnapshot.data!.data() as Map<String, dynamic>?;
                                    namaGuru = (guruData?['nama'] ?? 'Guru BK').toString();
                                  }
                                  return Text(
                                    'Diterima oleh: $namaGuru',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              ),
                              if (jadwal != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Jadwal: ${_formatTanggalJadwal(jadwal)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (tempat.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tempat: $tempat',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (catatanJadwal.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Catatan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  catatanJadwal,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                            if (deskripsi.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Deskripsi:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deskripsi,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

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

  String _formatTanggalJadwal(DateTime tanggal) {
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
    final hariNama = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'][tanggal.weekday % 7];
    
    return '$hariNama, $hari $namaBulan $tahun, $jam:$menit';
  }
}
