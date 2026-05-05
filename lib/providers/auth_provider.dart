import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthNotifier extends AsyncNotifier<AppUser?> {
  StreamSubscription<AuthState>? _subscription;

  @override
  FutureOr<AppUser?> build() async {
    final authService = ref.watch(authServiceProvider);
    
    // Cleanup subscription when the provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        try {
          final user = await authService.getUserProfile(session.user.id);
          state = AsyncValue.data(user);
        } catch (e, st) {
          state = AsyncValue.error(e, st);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });

    // Initial state
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return await authService.getUserProfile(session.user.id);
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authServiceProvider).signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authServiceProvider).signUp(email: email, password: password, name: name);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);
