import 'package:supabase_flutter/supabase_flutter.dart';

/// Converte exceções técnicas em mensagens claras para o jogador.
String friendlyError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'E-mail ou senha incorretos.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Este e-mail já está cadastrado. Tente fazer login.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar (veja sua caixa de entrada).';
    }
    if (m.contains('password should be at least')) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    if (m.contains('invalid') && m.contains('email')) return 'E-mail inválido.';
    return error.message;
  }
  if (error is PostgrestException) {
    return 'Erro no servidor: ${error.message}';
  }
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('XMLHttpRequest')) {
    return 'Sem conexão com o servidor. Verifique sua internet.';
  }
  return 'Algo deu errado: $text';
}
