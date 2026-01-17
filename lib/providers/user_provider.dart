import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahabatbk/providers/auth_provider.dart';

// Provider untuk Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider untuk mendapatkan user data dari Firestore berdasarkan UID
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);

  if (user == null) {
    return Stream.value(null);
  }

  return firestore
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data();
  });
});

// Provider untuk mendapatkan role user
final userRoleProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  final data = userData.valueOrNull;
  if (data == null) return null;
  return (data['role'] ?? '').toString().trim().toLowerCase();
});

// Provider untuk check apakah user adalah guru
final isTeacherProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'guru';
});

// Provider untuk check apakah user adalah siswa
final isStudentProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'siswa';
});

