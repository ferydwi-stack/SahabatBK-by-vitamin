import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahabatbk/providers/auth_provider.dart';

// Service untuk operasi authentication
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  // Login dengan email dan password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Login ke Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User tidak ditemukan.',
        );
      }

      // 2. Pastikan email sudah terverifikasi
      await user.reload();
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Email belum terverifikasi. Silakan cek email, klik link verifikasi, lalu login kembali.',
        };
      }

      // 3. Ambil data user di Firestore
      final usersRef = _firestore.collection('users');
      DocumentSnapshot<Map<String, dynamic>>? userDoc =
          await usersRef.doc(user.uid).get();

      // Jika doc dengan UID tidak ada, cari berdasarkan email
      if (!userDoc.exists) {
        final query = await usersRef
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          userDoc = query.docs.first;
        } else {
          return {
            'success': false,
            'error': 'Data pengguna tidak ditemukan di Firestore. Hubungi admin BK.',
          };
        }
      }

      final data = userDoc.data() ?? {};
      final role = (data['role'] ?? '').toString().trim().toLowerCase();

      return {
        'success': true,
        'role': role,
        'userData': data,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat login';

      if (e.code == 'user-not-found') {
        message = 'Pengguna tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      }

      return {
        'success': false,
        'error': message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Register user baru
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nama,
    required String id,
    required String role,
  }) async {
      User? createdUser;
    try {
      // 1. Buat akun Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = cred.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Gagal membuat akun. Silakan coba lagi.',
        };
      }

      createdUser = user;
      final uid = user.uid;

      // 2. Simpan profil ke Firestore (SEBELUM logout)
      try {
          await _firestore.collection('users').doc(uid).set({
            'email': email.trim(),
            'nama': nama.trim(),
            'kelas': '',
            'nip': role == 'guru' ? id.trim() : '',
            'nisn': role == 'siswa' ? id.trim() : '',
            'role': role.toLowerCase(),
            'photourl': '',
            'photoeditcount': 0,
          });
      } catch (firestoreError) {
        // Jika gagal simpan ke Firestore, hapus user dari Auth
        try {
          await user.delete();
        } catch (_) {
          // Ignore error delete
        }
        return {
          'success': false,
          'error': 'Gagal menyimpan data ke database: $firestoreError. Pastikan rules Firestore sudah di-deploy.',
        };
      }

      // 3. Kirim email verifikasi
      try {
        await user.sendEmailVerification();
      } catch (e) {
        // Jika gagal kirim email, tetap lanjutkan (bukan error fatal)
        print('Gagal kirim email verifikasi: $e');
      }

      // 4. Logout supaya user harus login lagi setelah verifikasi
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Registrasi berhasil! Cek email kamu untuk verifikasi sebelum login.',
      };
    } on FirebaseAuthException catch (e) {
      // Hapus user dari Auth jika sudah dibuat tapi gagal
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Ignore error delete
        }
      }

      String message = 'Terjadi kesalahan saat registrasi';

      if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else if (e.code == 'network-request-failed') {
        message = 'Tidak ada koneksi internet';
      }

      return {
        'success': false,
        'error': message,
      };
    } catch (e) {
      // Hapus user dari Auth jika sudah dibuat tapi gagal
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Ignore error delete
        }
      }

      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Email reset password telah dikirim. Cek email Anda.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat mengirim email reset password';

      if (e.code == 'user-not-found') {
        message = 'Email tidak terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      }

      return {
        'success': false,
        'error': message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Verifikasi kode (untuk reset password)
  Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String email,
  }) async {
    try {
      // Cek apakah user ada di Firestore
      final usersRef = _firestore.collection('users');
      final query = await usersRef
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Data pengguna tidak ditemukan di Firestore. Hubungi admin BK.',
        };
      }

      final userData = query.docs.first.data();
      final role = (userData['role'] ?? '').toString().trim().toLowerCase();

      // Untuk sekarang, verifikasi kode hanya cek apakah user ada
      // TODO: Implementasi verifikasi kode yang sebenarnya jika diperlukan
      // Misalnya menggunakan OTP atau action code dari email
      
      return {
        'success': true,
        'email': email,
        'role': role,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Reset password dengan email (setelah verifikasi)
  Future<Map<String, dynamic>> resetPasswordAfterVerification({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Cek apakah user ada di Firestore
      final usersRef = _firestore.collection('users');
      final query = await usersRef
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Data pengguna tidak ditemukan di Firestore. Hubungi admin BK.',
        };
      }

      // Cari user di Firebase Auth berdasarkan email
      try {
        // Coba sign in dengan password sementara untuk mendapatkan user
        // Tapi ini tidak mungkin karena kita tidak tahu password lama
        
        // Alternatif: gunakan admin SDK atau cara lain
        // Untuk sekarang, kita akan menggunakan pendekatan yang berbeda
        
        // Kirim email reset password dan minta user menggunakan link tersebut
        await _auth.sendPasswordResetEmail(email: email.trim());
        
        return {
          'success': false,
          'error': 'Silakan gunakan link reset password yang dikirim ke email Anda untuk mengubah password.',
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Gagal reset password: $e',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Reset password dengan email dan action code (dari email link)
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      return {
        'success': true,
        'message': 'Password berhasil direset',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal reset password';
      
      if (e.code == 'expired-action-code') {
        message = 'Kode sudah kadaluarsa. Silakan minta reset password lagi.';
      } else if (e.code == 'invalid-action-code') {
        message = 'Kode tidak valid. Silakan cek email Anda.';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }

      return {
        'success': false,
        'error': message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }
}

// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = FirebaseFirestore.instance;
  return AuthService(auth, firestore);
});

