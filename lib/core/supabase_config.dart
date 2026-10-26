/// Credenciais públicas do projeto Supabase.
///
/// A chave "anon"/"publishable" pode ficar no app: quem protege os dados
/// são as políticas RLS e as funções do banco (veja supabase/schema.sql).
///
/// Também é possível sobrescrever na execução:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zztylboaoiinrvcjswap.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_YTikHwqY81BmdZ_ciiO_5A_4ets8cSZ',
  );
}
