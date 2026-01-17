import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _LogoImage(size: size);
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(size * 0.12),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.blue.shade400,
              size: size * 0.5,
            ),
          );
        },
      ),
    );
  }
}

