import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahabatbk/screens/auth/forgot_password_page.dart';
import 'package:sahabatbk/screens/auth/register_page.dart';
import 'package:sahabatbk/screens/student/student_home_page.dart';
import 'package:sahabatbk/screens/teacher/teacher_home_page.dart';
import 'package:sahabatbk/widgets/app_logo.dart';
import 'package:sahabatbk/widgets/custom_text_field.dart';
import 'package:sahabatbk/widgets/custom_button.dart';
import 'package:sahabatbk/providers/auth_service.dart';
import 'package:sahabatbk/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final role = result['role'] as String;
      
      // Routing berdasarkan role
      if (role == 'guru') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentHomePage()),
        );
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const AppLogo(),
                const SizedBox(height: 48),
                Text(
                  'Selamat Datang',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun Anda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 40),
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
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text('Lupakan kata sandi?'),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Masuk',
                  onPressed: _handleLogin,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('Daftar'),
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
