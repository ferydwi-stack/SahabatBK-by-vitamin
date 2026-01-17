// lib/screens/teacher/teacher_incoming_requests_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahabatbk/theme/app_colors.dart';
import 'teacher_common_widgets.dart';

// Dialog untuk atur jadwal
class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog();

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tempatController = TextEditingController();
  final _catatanController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _tempatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String? _getTanggalText() {
    if (_selectedDate == null) return null;
    return '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
  }

  String? _getWaktuText() {
    if (_selectedTime == null) return null;
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  void _handleSimpan() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu terlebih dahulu')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'tanggal': _selectedDate,
        'waktu': _selectedTime,
        'tempat': _tempatController.text.trim(),
        'catatan': _catatanController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Jadwal Konseling'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal
              const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(_getTanggalText() ?? 'Pilih Tanggal'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Waktu
              const Text('Waktu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(_getWaktuText() ?? 'Pilih Waktu'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tempat
              const Text('Tempat', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _tempatController,
                decoration: teacherInputDecoration().copyWith(
                  hintText: 'Masukkan tempat konseling',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan tempat konseling';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Catatan
              const Text('Catatan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: teacherInputDecoration().copyWith(
                  hintText: 'Masukkan catatan (opsional)',
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSimpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
          ),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class TeacherIncomingRequestsPage extends StatelessWidget {
  const TeacherIncomingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    if (user == null) {
      return const Column(
        children: [
          TeacherHeader(title: 'Pengajuan Konseling Masuk'),
          Expanded(
            child: Center(child: Text('Anda belum login')),
          ),
        ],
      );
    }

    return Column(
      children: [
        const TeacherHeader(title: 'Pengajuan Konseling Masuk'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('pengajuan')
                .where('status', whereIn: ['', 'Menunggu', 'Diterima'])
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
                  child: Text('Belum ada pengajuan'),
                );
              }

              // Filter: hanya pengajuan yang belum diterima (guru_uid null/kosong) 
              // ATAU yang sudah diterima oleh guru yang login
              final user = FirebaseAuth.instance.currentUser;
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final guruUid = data['guru_uid']?.toString();
                final status = (data['status'] ?? '').toString();
                
                // Jika belum diterima (status kosong/Menunggu dan guru_uid kosong)
                if ((status.isEmpty || status == 'Menunggu') && (guruUid == null || guruUid.isEmpty)) {
                  return true;
                }
                
                // Jika sudah diterima, hanya tampilkan jika diterima oleh guru yang login
                if (status == 'Diterima' && user != null && guruUid == user.uid) {
                  return true;
                }
                
                return false;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text('Belum ada pengajuan'),
                );
              }

              // Sort by tanggal_pengajuan descending (client-side)
              final docs = filteredDocs
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTs = aData['tanggal_pengajuan'] as Timestamp?;
                  final bTs = bData['tanggal_pengajuan'] as Timestamp?;
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
                  return TeacherRequestCard(
                    docId: doc.id,
                    data: doc.data() as Map<String, dynamic>,
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

class TeacherRequestCard extends StatelessWidget {
  const TeacherRequestCard({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

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

  Future<void> _aturJadwal(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _ScheduleDialog(),
    );

    if (result == null) return;

    // Gabungkan tanggal dan waktu
    final jadwalDateTime = DateTime(
      result['tanggal'].year,
      result['tanggal'].month,
      result['tanggal'].day,
      result['waktu'].hour,
      result['waktu'].minute,
    );

    // Update ke Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda belum login')),
          );
        }
        return;
      }

      await firestore.collection('pengajuan').doc(docId).update({
        'status': 'Diterima',
        'tanggal_jadwal': Timestamp.fromDate(jadwalDateTime),
        'tempat': result['tempat'],
        'guru_uid': user.uid, // Simpan UID guru yang menerima
        if (result['catatan'].toString().isNotEmpty) 'catatan_jadwal': result['catatan'],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal berhasil diatur'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengatur jadwal: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final String topik = (data['topik'] ?? '').toString();
    final String deskripsi = (data['deskripsi'] ?? '').toString();
    final String nisn = (data['nisn'] ?? '').toString();
    final String status = (data['status'] ?? '').toString();
    final Timestamp? tanggalTs = data['tanggal_pengajuan'] as Timestamp?;
    final DateTime? tanggal = tanggalTs?.toDate();
    final Timestamp? jadwalTs = data['tanggal_jadwal'] as Timestamp?;
    final DateTime? jadwal = jadwalTs?.toDate();

    return FutureBuilder<String>(
      future: _getNamaSiswa(nisn),
      builder: (context, snapshot) {
        final namaSiswa = snapshot.data ?? 'Siswa';
        final statusText = status.isEmpty ? 'Menunggu' : status;
        final tanggalText = tanggal != null 
            ? _formatTanggal(tanggal)
            : '-';

        return TeacherCardContainer(
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
              const SizedBox(height: 6),
              teacherInfoRow('Topik', topik.isEmpty ? '-' : topik),
              teacherInfoRow('Deskripsi', deskripsi.isEmpty ? '-' : deskripsi),
              teacherInfoRow('Tanggal Pengajuan', tanggalText),
              if (jadwal != null) ...[
                teacherInfoRow('Jadwal Konseling', _formatTanggal(jadwal) + 
                    ' ${jadwal.hour.toString().padLeft(2, '0')}:${jadwal.minute.toString().padLeft(2, '0')}'),
                if (data['tempat'] != null && (data['tempat'] as String).isNotEmpty)
                  teacherInfoRow('Tempat', data['tempat']),
                if (data['catatan_jadwal'] != null && (data['catatan_jadwal'] as String).isNotEmpty)
                  teacherInfoRow('Catatan', data['catatan_jadwal']),
              ],
              teacherInfoRow('Status', statusText),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status.isEmpty || status == 'Menunggu')
                    TextButton(
                      onPressed: () => _aturJadwal(context),
                      child: const Text('Atur Jadwal'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

