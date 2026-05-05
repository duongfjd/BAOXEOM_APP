import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Sign up
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final User? user = res.user;
      if (user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // Wait a moment for the Supabase trigger to finish inserting into public.users
      await Future.delayed(const Duration(milliseconds: 500));

      return await getUserProfile(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred during sign up: $e');
    }
  }

  // Sign in
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      return await getUserProfile(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred during sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Fetch user profile from public.users
  Future<AppUser> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
          
      return AppUser.fromMap(response);
    } catch (e) {
      // Fallback if public.users row doesn't exist or RLS blocks it
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        return AppUser(
          id: currentUser.id,
          email: currentUser.email ?? '',
          name: currentUser.userMetadata?['name'] as String?,
          createdAt: DateTime.parse(currentUser.createdAt),
        );
      }
      throw Exception('Failed to fetch user profile: $e');
    }
  }
}
