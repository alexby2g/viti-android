import 'package:flutter/material.dart';

enum VitiTone { neutral, primary, info, success, warning, danger }

class VitiPageHeader extends StatelessWidget {
  const VitiPageHeader({
    required this.title,
    required this.subtitle,
    this.eyebrow = 'AGR STUDIO · VITI',
    this.actions = const <Widget>[],
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final heading = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 18, height: 3, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(99))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      eyebrow.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: (compact ? Theme.of(context).textTheme.headlineSmall : Theme.of(context).textTheme.headlineMedium)?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        );

        if (compact || actions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
          ],
        );
      },
    );
  }
}

class VitiPanel extends StatelessWidget {
  const VitiPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tone = VitiTone.neutral,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VitiTone tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = vitiToneColor(context, tone);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = selected ? Color.alphaBlend(toneColor.withValues(alpha: dark ? .13 : .07), colors.surface) : colors.surface;
    final border = selected ? toneColor.withValues(alpha: .48) : colors.outlineVariant.withValues(alpha: .92);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          if (!dark) BoxShadow(color: const Color(0xFF092B55).withValues(alpha: selected ? .09 : .045), blurRadius: selected ? 24 : 16, offset: const Offset(0, 6)),
          if (dark && selected) BoxShadow(color: toneColor.withValues(alpha: .08), blurRadius: 22, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: content),
    );
  }
}

class VitiMetricTile extends StatelessWidget {
  const VitiMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = VitiTone.primary,
    this.caption,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final VitiTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = vitiToneColor(context, tone);
    return SizedBox(
      width: 224,
      child: VitiPanel(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: toneColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: toneColor, size: 20),
                ),
                const Spacer(),
                if (onTap != null) Icon(Icons.arrow_outward, size: 16, color: colors.onSurfaceVariant.withValues(alpha: .62)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: .95, letterSpacing: -.7)),
            const SizedBox(height: 7),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, height: 1.25)),
            ],
          ],
        ),
      ),
    );
  }
}

class VitiStatusBadge extends StatelessWidget {
  const VitiStatusBadge(this.label, {this.tone = VitiTone.neutral, this.icon, super.key});

  final String label;
  final VitiTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = vitiToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: .1)),
        ],
      ),
    );
  }
}

class VitiSearchField extends StatelessWidget {
  const VitiSearchField({required this.controller, required this.hint, required this.onChanged, this.width = 330, super.key});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, minWidth: 220),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 19),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close, size: 17),
                ),
        ),
      ),
    );
  }
}

class VitiEntityRow extends StatelessWidget {
  const VitiEntityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.badges = const <Widget>[],
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final List<Widget> badges;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .12 : .055) : colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? colors.primary.withValues(alpha: .46) : colors.outlineVariant.withValues(alpha: .82)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: selected ? colors.primary.withValues(alpha: .13) : colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, size: 20, color: selected ? colors.primary : colors.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant, height: 1.3)),
                    if (badges.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: badges)],
                  ]),
                ),
                const SizedBox(width: 10),
                trailing ?? Icon(Icons.chevron_right, color: colors.onSurfaceVariant.withValues(alpha: .7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VitiInspector extends StatelessWidget {
  const VitiInspector({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.badges = const <Widget>[],
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> badges;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return VitiPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: colors.primary.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: colors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant, height: 1.3)),
                    if (badges.isNotEmpty) ...[const SizedBox(height: 9), Wrap(spacing: 6, runSpacing: 6, children: badges)],
                  ]),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .8)),
          Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
          if (actions.isNotEmpty) ...[
            Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .8)),
            Padding(padding: const EdgeInsets.all(14), child: Wrap(spacing: 8, runSpacing: 8, children: actions)),
          ],
        ],
      ),
    );
  }
}

class VitiKeyValue extends StatelessWidget {
  const VitiKeyValue(this.label, this.value, {this.icon, super.key});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 17, color: colors.onSurfaceVariant), const SizedBox(width: 9)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: colors.onSurfaceVariant)),
              const SizedBox(height: 4),
              SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
            ]),
          ),
        ],
      ),
    );
  }
}

class VitiEmptyState extends StatelessWidget {
  const VitiEmptyState({required this.title, required this.message, this.icon = Icons.inbox_outlined, this.action, super.key});

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return VitiPanel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 54, height: 54, decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(17)), child: Icon(icon, size: 27, color: colors.onSurfaceVariant)),
                const SizedBox(height: 14),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant, height: 1.4)),
                if (action != null) ...[const SizedBox(height: 15), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color vitiToneColor(BuildContext context, VitiTone tone) {
  final colors = Theme.of(context).colorScheme;
  return switch (tone) {
    VitiTone.primary => colors.primary,
    VitiTone.info => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF75B8FF) : const Color(0xFF1565C0),
    VitiTone.success => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6EE7B7) : const Color(0xFF20895A),
    VitiTone.warning => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFC66B) : const Color(0xFFB56B00),
    VitiTone.danger => colors.error,
    VitiTone.neutral => colors.onSurfaceVariant,
  };
}

VitiTone vitiToneForStatus(String? raw) {
  final value = (raw ?? '').toLowerCase().trim();
  if ({'activo', 'aprobada', 'aprobado', 'pagado', 'confirmado', 'entregado', 'entregada', 'finalizado', 'finalizada', 'produccion', 'resuelto', 'cerrado'}.contains(value)) return VitiTone.success;
  if ({'borrador', 'pendiente', 'pendiente_revision', 'pendiente_anticipo', 'en_revision', 'en_espera', 'beta', 'en_pruebas'}.contains(value)) return VitiTone.warning;
  if ({'rechazado', 'rechazada', 'cancelado', 'cancelada', 'retirado', 'fallido', 'vencido'}.contains(value)) return VitiTone.danger;
  if ({'convertida', 'desarrollo', 'analisis', 'diseno', 'implementacion', 'mantenimiento'}.contains(value)) return VitiTone.primary;
  return VitiTone.neutral;
}

String vitiPretty(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Sin definir';
  final normalized = text.replaceAll('_', ' ');
  return normalized[0].toUpperCase() + normalized.substring(1);
}
