import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sahabatbk/screens/auth/login_page.dart';
import 'package:sahabatbk/widgets/app_logo.dart';
import 'package:sahabatbk/providers/auth_service.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String? email;
  
  const ResetPasswordPage({super.key, this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  static const primaryColor = Color(0xFF3366FF);
  static const fieldColor = Color(0xFFF2F0F0);
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitNewPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final newPassword = _passwordController.text.trim();
      final firestore = FirebaseFirestore.instance;

      // Pastikan email ada
      if (widget.email == null || widget.email!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email tidak ditemukan'),
            ),
          );
        }
        return;
      }

      // Cari user berdasarkan email di Firestore
      final usersRef = firestore.collection('users');
      final query = await usersRef
          .where('email', isEqualTo: widget.email!.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data pengguna tidak ditemukan di Firestore. Hubungi admin BK.'),
            ),
          );
        }
        return;
      }

      // Untuk reset password di Firebase, kita perlu:
      // 1. User sudah login (untuk updatePassword), ATAU
      // 2. Action code dari email link (untuk confirmPasswordReset)
      
      // Karena user belum login dan kita tidak punya action code,
      // kita akan kirim email reset password dan minta user menggunakan link tersebut
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: widget.email!.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link reset password telah dikirim ke email Anda. Silakan buka email dan klik link tersebut untuk mengubah password.'),
              duration: Duration(seconds: 6),
              backgroundColor: Colors.blue,
            ),
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Gagal mengirim email reset password';
        
        if (e.code == 'user-not-found') {
          message = 'Email tidak terdaftar';
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kata sandi baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                const AppLogo(size: 150),
                const SizedBox(height: 20),
                if (widget.email != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(height: 8),
                        const Text(
                          'Untuk mengubah password, silakan gunakan link reset password yang telah dikirim ke email Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${widget.email}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Text(
                  'Kata sandi baru',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: _passwordController,
                  hint: 'Kata sandi baru',
                  obscure: _obscurePassword,
                  onToggle: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Konfir kata sandi',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmController,
                  hint: 'Konfir sandi baru',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _loading ? null : _submitNewPassword,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(
                              color: Colors.white,
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
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Isi $hint';
        }
        if (controller == _confirmController &&
            value != _passwordController.text) {
          return 'Konfirmasi tidak cocok';
        }
        if (controller == _passwordController && value.length < 6) {
          return 'Minimal 6 karakter';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
    );
  }
}
