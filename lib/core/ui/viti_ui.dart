import 'package:flutter/material.dart';

enum VitiTone { neutral, primary, info, success, warning, danger }

class VitiPageHeader extends StatelessWidget {
  const VitiPageHeader({required this.title, required this.subtitle, this.eyebrow = 'AGR STUDIO · VITI', this.actions = const <Widget>[], super.key});
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow.toUpperCase(), style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.6)),
            const SizedBox(height: 5),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.35)),
          ]),
        ),
        if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
      ],
    );
  }
}

class VitiPanel extends StatelessWidget {
  const VitiPanel({required this.child, this.padding = const EdgeInsets.all(18), this.tone = VitiTone.neutral, this.selected = false, this.onTap, super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VitiTone tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = vitiToneColor(context, tone);
    final fill = selected ? Color.alphaBlend(toneColor.withValues(alpha: .10), colors.surface) : colors.surface;
    final border = selected ? toneColor.withValues(alpha: .54) : colors.outlineVariant.withValues(alpha: .72);
    final content = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: selected ? [BoxShadow(color: toneColor.withValues(alpha: .08), blurRadius: 22, offset: const Offset(0, 8))] : const [],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: content));
  }
}

class VitiMetricTile extends StatelessWidget {
  const VitiMetricTile({required this.label, required this.value, required this.icon, this.tone = VitiTone.primary, this.caption, this.onTap, super.key});
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
      width: 214,
      child: VitiPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: toneColor.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: toneColor, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            if (caption != null) ...[const SizedBox(height: 3), Text(caption!, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant))],
          ])),
        ]),
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
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: .26))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)], Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color))]),
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
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isEmpty ? null : IconButton(tooltip: 'Limpiar', onPressed: () {controller.clear(); onChanged('');}, icon: const Icon(Icons.close, size: 18)),
        ),
      ),
    );
  }
}

class VitiEntityRow extends StatelessWidget {
  const VitiEntityRow({required this.title, required this.subtitle, required this.icon, required this.onTap, this.selected = false, this.badges = const <Widget>[], this.trailing, super.key});
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
        color: selected ? colors.primaryContainer.withValues(alpha: .42) : colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? colors.primary.withValues(alpha: .54) : colors.outlineVariant.withValues(alpha: .65))),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: selected ? colors.primary.withValues(alpha: .15) : colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: selected ? colors.primary : colors.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant, height: 1.25)),
                if (badges.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: badges)],
              ])),
              const SizedBox(width: 10),
              trailing ?? Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class VitiInspector extends StatelessWidget {
  const VitiInspector({required this.title, required this.subtitle, required this.icon, required this.children, this.badges = const <Widget>[], this.actions = const <Widget>[], super.key});
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: colors.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              if (badges.isNotEmpty) ...[const SizedBox(height: 9), Wrap(spacing: 6, runSpacing: 6, children: badges)],
            ])),
          ]),
        ),
        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .7)),
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        if (actions.isNotEmpty) ...[Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .7)), Padding(padding: const EdgeInsets.all(14), child: Wrap(spacing: 8, runSpacing: 8, children: actions))],
      ]),
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
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 17, color: colors.onSurfaceVariant), const SizedBox(width: 9)],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: colors.onSurfaceVariant)),
          const SizedBox(height: 3),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
        ])),
      ]),
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
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ]),
        ),
      ),
    );
  }
}

Color vitiToneColor(BuildContext context, VitiTone tone) {
  final colors = Theme.of(context).colorScheme;
  return switch (tone) {
    VitiTone.primary => colors.primary,
    VitiTone.info => const Color(0xFF2F9DD3),
    VitiTone.success => const Color(0xFF2FA86F),
    VitiTone.warning => const Color(0xFFE59A2F),
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
