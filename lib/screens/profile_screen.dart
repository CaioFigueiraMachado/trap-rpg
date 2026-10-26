import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../services/auth_service.dart';
import '../services/game_repository.dart';
import '../widgets/state_views.dart';

class _ProfileData {
  const _ProfileData(this.stats, this.history);
  final PlayerStats stats;
  final List<MissionHistoryEntry> history;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = GameRepository.instance;
  late Future<_ProfileData> _future = _load();

  @override
  void initState() {
    super.initState();
    _repo.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.removeListener(_reload);
    super.dispose();
  }

  Future<_ProfileData> _load() async {
    final r = await Future.wait<dynamic>([_repo.fetchStats(), _repo.fetchHistory()]);
    return _ProfileData(r[0] as PlayerStats, r[1] as List<MissionHistoryEntry>);
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _editNickname(String current) async {
    final controller = TextEditingController(text: current);
    final formKey = GlobalKey<FormState>();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar apelido'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLength: 20,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Apelido'),
            validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Mínimo de 2 caracteres' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName == current) return;
    try {
      await _repo.updateNickname(newName);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Apelido atualizado!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Seu progresso fica salvo no servidor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok ?? false) {
      // O redirect do GoRouter manda para o login quando a sessão acaba.
      await AuthService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFIL'),
        actions: [
          IconButton(tooltip: 'Sair', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureView<_ProfileData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final s = data.stats;
          final level = PlayerLevel.of(s.profile.points);

          return LayoutBuilder(builder: (context, constraints) => RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: Breakpoints.pagePadding(context, maxWidth: 900, available: constraints.maxWidth),
              children: [
                // Cabeçalho do jogador
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [AppColors.primaryDark, Color(0xFFEC4899)]),
                          border: Border.all(color: AppColors.gold, width: 3),
                        ),
                        child: Text(s.profile.nickname.substring(0, 1).toUpperCase(),
                            style: AppTheme.display(40)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.profile.nickname, style: AppTheme.display(22)),
                          IconButton(
                            tooltip: 'Alterar apelido',
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editNickname(s.profile.nickname),
                          ),
                        ],
                      ),
                      Text(_repo.email ?? '', style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text('Nível $level • ${PlayerLevel.title(level)}',
                          style: const TextStyle(
                              color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Estatísticas
                GridView.count(
                  crossAxisCount: Breakpoints.isTablet(context) ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _StatTile(icon: Icons.bolt, label: 'Pontuação', value: '${s.profile.points}', color: AppColors.accent),
                    _StatTile(icon: Icons.flag, label: 'Missões concluídas', value: '${s.missionsCompleted}/${s.totalMissions}', color: AppColors.primary),
                    _StatTile(icon: Icons.emoji_events, label: 'Conquistas', value: '${s.achievementsUnlocked}/${s.totalAchievements}', color: AppColors.gold),
                    _StatTile(icon: Icons.style, label: 'Cartas', value: '${s.cardsOwned}/${s.totalCards}', color: const Color(0xFF22D3EE)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('HISTÓRICO DE VITÓRIAS', style: AppTheme.display(14)),
                const SizedBox(height: 10),
                if (data.history.isEmpty)
                  const EmptyView(
                    message: 'Nenhuma missão concluída ainda. Bora pra primeira batalha!',
                    icon: Icons.history,
                  )
                else
                  for (final h in data.history)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(GameMeta.category(h.category).icon,
                            color: GameMeta.category(h.category).color),
                        title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(_formatDate(h.completedAt)),
                        trailing: Text('+${h.points}',
                            style: const TextStyle(
                                color: AppColors.accent, fontWeight: FontWeight.w800)),
                      ),
                    ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('SAIR DA CONTA'),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.display(18)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
