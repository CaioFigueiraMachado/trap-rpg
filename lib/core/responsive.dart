import 'package:flutter/material.dart';

/// Pontos de quebra para celular, tablet e computador (Flutter Web).
class Breakpoints {
  static const tablet = 700.0;
  static const desktop = 1000.0;

  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;

  /// Padding de página que centraliza listas roláveis em telas largas
  /// (a barra de rolagem continua na borda da janela).
  static EdgeInsets pagePadding(
    BuildContext context, {
    double maxWidth = 1200,
    double vertical = 16,
    double available = 0,
  }) {
    final width = available > 0 ? available : MediaQuery.sizeOf(context).width;
    final side = ((width - maxWidth) / 2).clamp(16.0, double.infinity);
    return EdgeInsets.symmetric(horizontal: side, vertical: vertical);
  }
}

/// Grade que muda o número de colunas conforme a largura disponível.
/// Os itens de uma mesma linha ficam com a mesma altura.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.maxColumns = 3,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns =
          ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);
      if (columns == 1) {
        return Column(children: [
          for (final child in children)
            Padding(padding: EdgeInsets.only(bottom: spacing), child: child),
        ]);
      }
      return Column(children: [
        for (var i = 0; i < children.length; i += columns)
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: i + j < children.length ? children[i + j] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ]);
    });
  }
}

/// Centraliza o conteúdo e limita a largura em telas grandes.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 1100});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
