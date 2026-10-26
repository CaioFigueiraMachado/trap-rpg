import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_repository.dart';

/// Autenticação por e-mail e senha (Supabase Auth).
class AuthService {
  static SupabaseClient get _db => Supabase.instance.client;

  static User? get currentUser => _db.auth.currentUser;
  static bool get isLoggedIn => _db.auth.currentSession != null;

  static Future<void> signIn({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Cria a conta. O apelido vai nos metadados e o trigger do banco
  /// cria o perfil + cartas iniciais. Retorna `true` se já entrou logado
  /// (ou `false` se o projeto exige confirmação por e-mail).
  static Future<bool> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    final response = await _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nickname': nickname.trim()},
    );
    return response.session != null;
  }

  static Future<void> signOut() async {
    GameRepository.instance.clearCache();
    await _db.auth.signOut();
  }
}
