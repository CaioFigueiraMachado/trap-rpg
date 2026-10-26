import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../widgets/app_logo.dart';

typedef _Destination = ({IconData icon, IconData selected, String label});

const _destinations = <_Destination>[
  (icon: Icons.map_outlined, selected: Icons.map, label: 'Missões'),
  (icon: Icons.style_outlined, selected: Icons.style, label: 'Cartas'),
  (icon: Icons.emoji_events_outlined, selected: Icons.emoji_events, label: 'Conquistas'),
  (icon: Icons.leaderboard_outlined, selected: Icons.leaderboard, label: 'Ranking'),
  (icon: Icons.person_outline, selected: Icons.person, label: 'Perfil'),
];

/// Estrutura das abas internas.
/// Celular: barra inferior. Tablet/computador: menu lateral.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isTablet(context)) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = Breakpoints.isDesktop(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 210,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.3),
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppLogo(size: extended ? 120 : 64, showSubtitle: extended),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: Colors.white10),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
