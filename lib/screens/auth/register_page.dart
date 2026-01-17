import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_page.dart';
import 'package:sahabatbk/widgets/app_logo.dart';
import 'package:sahabatbk/widgets/custom_text_field.dart';
import 'package:sahabatbk/widgets/custom_button.dart';
import 'package:sahabatbk/providers/auth_service.dart';
import 'package:sahabatbk/theme/app_colors.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(); // NIP / NISN
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'Guru';
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.register(
      email: _emailController.text,
      password: _passwordController.text,
      nama: _nameController.text,
      id: _idController.text,
      role: _selectedRole.toLowerCase(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] as String)),
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
                const AppLogo(size: 150),
                const SizedBox(height: 24),
                Text(
                  'Buat Akun Baru',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar untuk memulai',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Pilih Role',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: const [
                    DropdownMenuItem(value: 'Guru', child: Text('Guru')),
                    DropdownMenuItem(value: 'Siswa', child: Text('Siswa')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRole = value);
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _idController,
                  hintText: _selectedRole == 'Guru' ? 'NIP' : 'NISN',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan ${_selectedRole == 'Guru' ? 'NIP' : 'NISN'}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan email';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan password';
                    }
                    if (value.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Daftar',
                  onPressed: _handleRegister,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
