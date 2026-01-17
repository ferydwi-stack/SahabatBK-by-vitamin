import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahabatbk/screens/auth/login_page.dart';
import 'package:sahabatbk/screens/auth/reset_password_page.dart';
import 'package:sahabatbk/widgets/app_logo.dart';
import 'package:sahabatbk/widgets/custom_text_field.dart';
import 'package:sahabatbk/widgets/custom_button.dart';
import 'package:sahabatbk/providers/auth_service.dart';
import 'package:sahabatbk/theme/app_colors.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak ditemukan')),
      );
      return;
    }

    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.verifyCode(
      code: _codeController.text.trim(),
      email: widget.email!,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Setelah verifikasi berhasil, kirim email reset password
      try {
        final authService = ref.read(authServiceProvider);
        await authService.resetPassword(widget.email!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link reset password telah dikirim ke email Anda. Silakan buka email dan klik link tersebut untuk mengubah password.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        // Jika gagal kirim email, tetap lanjutkan
      }
      
      // Arahkan ke halaman login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] as String? ?? 'Kode verifikasi salah')),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifikasi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                const AppLogo(size: 150),
                const SizedBox(height: 32),
                Text(
                  'Masukkan Kode Verifikasi',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami telah mengirimkan kode verifikasi ke email Anda',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _codeController,
                  hintText: 'Masukkan kode verifikasi',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan kode verifikasi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: trigger resend code
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode verifikasi telah dikirim ulang'),
                      ),
                    );
                  },
                  child: const Text('Kirim ulang kode verifikasi'),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Verifikasi',
                  onPressed: _handleVerify,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

