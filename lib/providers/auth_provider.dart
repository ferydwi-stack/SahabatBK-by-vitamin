import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Stream provider untuk auth state changes
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Provider untuk current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
});

// Provider untuk check apakah user sudah login
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

