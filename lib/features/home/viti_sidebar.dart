import 'package:flutter/material.dart';

import '../../core/theme/appearance_controller.dart';

class VitiNavItem {
  const VitiNavItem(this.key, this.label, this.icon, {this.group = 'Principal'});

  final String key;
  final String label;
  final IconData icon;
  final String group;
}

class VitiSidebar extends StatelessWidget {
  const VitiSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.appearance,
    required this.userName,
    required this.role,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onLogout,
    this.companyName,
    this.onCompanyTap,
    super.key,
  });

  final List<VitiNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppearanceController appearance;
  final String userName;
  final String role;
  final String? companyName;
  final VoidCallback? onCompanyTap;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final groups = <String, List<MapEntry<int, VitiNavItem>>>{};
    for (var index = 0; index < items.length; index++) {
      groups.putIfAbsent(items[index].group, () => []).add(MapEntry(index, items[index]));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 84 : 268,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant.withValues(alpha: .45))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 12 : 16, 16, collapsed ? 12 : 10, 12),
              child: Row(
                children: [
                  _BrandMark(collapsed: collapsed),
                  if (!collapsed) ...[
                    const Spacer(),
                    IconButton(
                      tooltip: 'Contraer menú',
                      onPressed: onToggleCollapsed,
                      icon: const Icon(Icons.keyboard_double_arrow_left),
                    ),
                  ] else
                    const Spacer(),
                  if (collapsed)
                    IconButton(
                      tooltip: 'Expandir menú',
                      onPressed: onToggleCollapsed,
                      icon: const Icon(Icons.keyboard_double_arrow_right, size: 19),
                    ),
                ],
              ),
            ),
            if (!collapsed && companyName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Material(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onCompanyTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.business_outlined, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMPRESA ACTIVA', style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: colors.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Text(companyName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          if (onCompanyTap != null) const Icon(Icons.unfold_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                children: [
                  for (final group in groups.entries) ...[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                        child: Text(group.key.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: colors.onSurfaceVariant)),
                      )
                    else
                      const SizedBox(height: 8),
                    for (final entry in group.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _SidebarTile(
                          item: entry.value,
                          selected: entry.key == selectedIndex,
                          collapsed: collapsed,
                          onTap: () => onSelected(entry.key),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _AppearanceTile(controller: appearance, collapsed: collapsed),
                  const SizedBox(height: 4),
                  if (!collapsed)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      leading: CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.onPrimaryContainer, child: Text(_initials(userName))),
                      title: Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(_pretty(role), style: TextStyle(color: colors.onSurfaceVariant)),
                      trailing: IconButton(tooltip: 'Cerrar sesión', onPressed: onLogout, icon: const Icon(Icons.logout)),
                    )
                  else
                    IconButton.filledTonal(tooltip: 'Cerrar sesión', onPressed: onLogout, icon: const Icon(Icons.logout)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitiMobileDrawer extends StatelessWidget {
  const VitiMobileDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.appearance,
    required this.userName,
    required this.role,
    required this.onLogout,
    this.companyName,
    this.onCompanyTap,
    super.key,
  });

  final List<VitiNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppearanceController appearance;
  final String userName;
  final String role;
  final String? companyName;
  final VoidCallback? onCompanyTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, 10), child: Align(alignment: Alignment.centerLeft, child: _BrandMark(collapsed: false))),
          if (companyName != null)
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(companyName!, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: const Text('Empresa activa'),
              trailing: onCompanyTap == null ? null : const Icon(Icons.unfold_more),
              onTap: onCompanyTap,
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SidebarTile(item: items[index], selected: selectedIndex == index, collapsed: false, onTap: () => onSelected(index)),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _AppearanceTile(controller: appearance, collapsed: false),
                ListTile(
                  leading: CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.onPrimaryContainer, child: Text(_initials(userName))),
                  title: Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_pretty(role)),
                  trailing: IconButton(onPressed: onLogout, tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected, required this.collapsed, required this.onTap});

  final VitiNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tile = Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 11),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon, size: 21, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600))),
              ],
            ],
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: item.label, child: tile) : tile;
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({required this.controller, required this.collapsed});

  final AppearanceController controller;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final icon = switch (controller.mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    final label = switch (controller.mode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
      ThemeMode.system => 'Sistema',
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Apariencia',
      initialValue: controller.mode,
      onSelected: controller.setMode,
      itemBuilder: (context) => const [
        PopupMenuItem(value: ThemeMode.system, child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.brightness_auto_outlined), title: Text('Sistema'))),
        PopupMenuItem(value: ThemeMode.light, child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.light_mode_outlined), title: Text('Claro'))),
        PopupMenuItem(value: ThemeMode.dark, child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.dark_mode_outlined), title: Text('Oscuro'))),
      ],
      child: collapsed
          ? SizedBox(height: 46, child: Center(child: Icon(icon)))
          : ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 10), leading: Icon(icon), title: const Text('Apariencia'), trailing: Text(label)),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mark = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: colors.surfaceContainerHighest,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('AGR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7)),
        Container(width: 23, height: 2, margin: const EdgeInsets.only(top: 3), color: colors.primary),
      ]),
    );
    if (collapsed) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('AGR STUDIO', style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: colors.onSurfaceVariant)),
          const Text('VITI', style: TextStyle(fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        ]),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
  if (parts.isEmpty) return 'V';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}

String _pretty(String value) => value.replaceAll('_', ' ');
