import 'package:flutter/material.dart';

import '../../core/theme/appearance_controller.dart';
import '../../core/theme/viti_theme.dart';

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
    final groups = _groupItems(items);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: collapsed ? 82 : 274,
      decoration: BoxDecoration(
        color: VitiTheme.navy,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: .08))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 26, offset: const Offset(8, 0))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 12 : 18, 18, collapsed ? 12 : 10, 14),
              child: Row(
                children: [
                  _BrandMark(collapsed: collapsed),
                  if (!collapsed) const Spacer(),
                  if (!collapsed)
                    _NavyIconButton(
                      tooltip: 'Contraer menú',
                      icon: Icons.keyboard_double_arrow_left,
                      onPressed: onToggleCollapsed,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _NavyIconButton(
                        tooltip: 'Expandir menú',
                        icon: Icons.keyboard_double_arrow_right,
                        onPressed: onToggleCollapsed,
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    border: Border.all(color: Colors.white.withValues(alpha: .09)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.desktop_windows_outlined, size: 16, color: Color(0xFF9DD5FF)),
                      SizedBox(width: 8),
                      Expanded(child: Text('VITI Native', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                      _NativeBadge(),
                    ],
                  ),
                ),
              ),
            if (companyName != null)
              Padding(
                padding: EdgeInsets.fromLTRB(collapsed ? 10 : 14, 4, collapsed ? 10 : 14, 9),
                child: collapsed
                    ? Tooltip(
                        message: companyName!,
                        child: _CompanyCompact(onTap: onCompanyTap),
                      )
                    : _CompanyCard(companyName: companyName!, onTap: onCompanyTap),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(collapsed ? 9 : 10, 2, collapsed ? 9 : 10, 10),
                children: [
                  for (final group in groups.entries) ...[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 7),
                        child: Text(
                          group.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.35,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: .48),
                          ),
                        ),
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
            Container(height: 1, color: Colors.white.withValues(alpha: .08)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _AppearanceTile(controller: appearance, collapsed: collapsed),
                  const SizedBox(height: 5),
                  _UserTile(
                    userName: userName,
                    role: role,
                    collapsed: collapsed,
                    onLogout: onLogout,
                  ),
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
    final groups = _groupItems(items);
    return ColoredBox(
      color: VitiTheme.navy,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Align(alignment: Alignment.centerLeft, child: _BrandMark(collapsed: false)),
            ),
            if (companyName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _CompanyCard(companyName: companyName!, onTap: onCompanyTap),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                children: [
                  for (final group in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 15, 12, 7),
                      child: Text(
                        group.key.toUpperCase(),
                        style: TextStyle(fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .48)),
                      ),
                    ),
                    for (final entry in group.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _SidebarTile(
                          item: entry.value,
                          selected: selectedIndex == entry.key,
                          collapsed: false,
                          onTap: () => onSelected(entry.key),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: .08)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _AppearanceTile(controller: appearance, collapsed: false),
                  const SizedBox(height: 4),
                  _UserTile(userName: userName, role: role, collapsed: false, onLogout: onLogout),
                ],
              ),
            ),
          ],
        ),
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
    final tile = Material(
      color: selected ? Colors.white.withValues(alpha: .13) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: .06),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: selected ? Colors.white.withValues(alpha: .10) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon, size: 20, color: selected ? Colors.white : const Color(0xFFB8CEE5)),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(color: selected ? Colors.white : const Color(0xFFD8E6F4), fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
                  ),
                ),
                if (selected) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF75B8FF), shape: BoxShape.circle)),
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
          ? SizedBox(height: 44, child: Center(child: Icon(icon, color: const Color(0xFFB8CEE5), size: 20)))
          : Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
              child: Row(children: [Icon(icon, color: const Color(0xFFB8CEE5), size: 20), const SizedBox(width: 12), const Expanded(child: Text('Apariencia', style: TextStyle(color: Color(0xFFD8E6F4), fontWeight: FontWeight.w600))), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 11))]),
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.userName, required this.role, required this.collapsed, required this.onLogout});

  final String userName;
  final String role;
  final bool collapsed;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Tooltip(
        message: '$userName · ${_pretty(role)}',
        child: SizedBox(
          height: 46,
          child: Center(
            child: IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Color(0xFFB8CEE5), size: 20),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: .07))),
      child: Row(
        children: [
          CircleAvatar(radius: 17, backgroundColor: const Color(0xFF1D5F9F), foregroundColor: Colors.white, child: Text(_initials(userName), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(_pretty(role), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 10)),
            ]),
          ),
          IconButton(tooltip: 'Cerrar sesión', onPressed: onLogout, icon: const Icon(Icons.logout, color: Color(0xFFB8CEE5), size: 19)),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('AGR', style: TextStyle(color: VitiTheme.navy, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7)),
        Container(width: 23, height: 2, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(color: VitiTheme.blue, borderRadius: BorderRadius.circular(99))),
      ]),
    );
    if (collapsed) return mark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark,
      const SizedBox(width: 11),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('AGR STUDIO', style: TextStyle(fontSize: 9, letterSpacing: 1.15, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: .55))),
        const Text('VITI', style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1.55, fontWeight: FontWeight.w900, height: 1.05)),
      ]),
    ]);
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.companyName, this.onTap});
  final String companyName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D3A6C),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withValues(alpha: .08))),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business_outlined, color: Color(0xFF9DD5FF), size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEGOCIO ACTIVO', style: TextStyle(fontSize: 8, letterSpacing: 1.05, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .45))), const SizedBox(height: 2), Text(companyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))])),
            if (onTap != null) const Icon(Icons.unfold_more, size: 17, color: Color(0xFFB8CEE5)),
          ]),
        ),
      ),
    );
  }
}

class _CompanyCompact extends StatelessWidget {
  const _CompanyCompact({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(11), child: const SizedBox(width: 48, height: 44, child: Icon(Icons.business_outlined, color: Color(0xFF9DD5FF), size: 20))),
    );
  }
}

class _NavyIconButton extends StatelessWidget {
  const _NavyIconButton({required this.tooltip, required this.icon, required this.onPressed, this.compact = false});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 28 : 36,
      height: 36,
      child: IconButton(tooltip: tooltip, onPressed: onPressed, padding: EdgeInsets.zero, icon: Icon(icon, color: const Color(0xFFB8CEE5), size: 19)),
    );
  }
}

class _NativeBadge extends StatelessWidget {
  const _NativeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFF2FA86F).withValues(alpha: .18), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: .25))),
      child: const Text('NATIVO', style: TextStyle(color: Color(0xFF9CF2CC), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .6)),
    );
  }
}

Map<String, List<MapEntry<int, VitiNavItem>>> _groupItems(List<VitiNavItem> items) {
  final groups = <String, List<MapEntry<int, VitiNavItem>>>{};
  for (var index = 0; index < items.length; index++) {
    groups.putIfAbsent(items[index].group, () => []).add(MapEntry(index, items[index]));
  }
  return groups;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
  if (parts.isEmpty) return 'VT';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}

String _pretty(String value) {
  final text = value.replaceAll('_', ' ');
  if (text.isEmpty) return 'Usuario';
  return text[0].toUpperCase() + text.substring(1);
}
