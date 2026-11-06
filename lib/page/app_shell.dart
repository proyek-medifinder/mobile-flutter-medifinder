import 'package:medifinder/page/widgets/appearance_picker.dart';
import 'package:flutter/material.dart';
import 'package:medifinder/page/tabs/chatbot_tab.dart';
import 'package:medifinder/page/tabs/home_tab.dart';
import 'package:medifinder/page/tabs/obat_tab.dart';
import 'package:medifinder/page/tabs/profile_tab.dart';
import 'package:medifinder/page/tabs/search_tab.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/page/widgets/logout_dialog.dart';
import 'package:medifinder/services/notification_permission_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialIndex = 0,
    this.requestPermissions = true,
  });
  final int initialIndex;
  final bool requestPermissions;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;
  final Set<int> _visited = {};
  String? _photo;
  static const labels = [
    'Beranda',
    'Cari Apotek',
    'MediBot',
    'Cari Obat',
    'Profil',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.storefront_outlined,
    Icons.smart_toy_outlined,
    Icons.medication_outlined,
    Icons.person_outline_rounded,
  ];
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
    _visited.add(_index);
    _loadAvatar();
    if (widget.requestPermissions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) NotificationPermissionService.requestWithoutContext();
      });
    }
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _photo = prefs.getString('profile_picture'));
  }

  void _navigate(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
    if (i == 4) _loadAvatar();
  }

  Widget _page(int i) => switch (i) {
    0 => HomeTab(onNavigateTab: _navigate),
    1 => const SearchTab(),
    2 => const ChatbotTab(),
    3 => ObatTab(onNavigateTab: _navigate),
    _ => const ProfileTab(),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppUi.colors(context).background,
    appBar: AppBar(
      toolbarHeight: 62,
      titleSpacing: 0,
      leading: Builder(
        builder:
            (ctx) => IconButton(
              tooltip: 'Buka menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
      ),
      title: const Align(
        alignment: Alignment.centerLeft,
        child: MediFinderLogo(width: 155),
      ),
      actions: [
        const AppearanceButton(),
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: IconButton(
            tooltip: 'Buka profil',
            onPressed: () => _navigate(4),
            icon: AccountAvatar(photo: _photo, radius: 18),
          ),
        ),
      ],
    ),
    drawer: Drawer(
      backgroundColor: AppUi.colors(context).surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: MediFinderLogo(width: 215),
            ),
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: ListTile(
                  selected: _index == i,
                  selectedColor: AppUi.primary,
                  selectedTileColor: AppUi.colors(context).softTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(icons[i]),
                  title: Text(
                    labels[i],
                    style: AppUi.text(
                      fontWeight:
                          _index == i ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(i);
                  },
                ),
              ),
            ),
            const Spacer(),
            const Divider(indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                ),
                title: Text(
                  'Keluar dari Akun',
                  style: AppUi.text(color: AppUi.colors(context).error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  logoutAccount(context);
                },
              ),
            ),
          ],
        ),
      ),
    ),
    body: IndexedStack(
      index: _index,
      children: List.generate(
        5,
        (i) => _visited.contains(i) ? _page(i) : const SizedBox.shrink(),
      ),
    ),
    bottomNavigationBar: ClinicalBottomNav(
      index: _index,
      onSelected: _navigate,
    ),
  );
}

class ClinicalBottomNav extends StatelessWidget {
  const ClinicalBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppUi.colors(context).surface,
      border: Border(top: BorderSide(color: AppUi.colors(context).line)),
      boxShadow: [
        BoxShadow(
          color: AppUi.primary.withValues(alpha: .06),
          blurRadius: 28,
          offset: const Offset(0, -6),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 2)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), AppUi.primary],
                            ),
                            border: Border.all(
                              color: AppUi.colors(context).surface,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppUi.primary.withValues(alpha: .2),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        )
                      else
                        Icon(
                          _AppShellState.icons[i],
                          color:
                              i == index
                                  ? AppUi.colors(context).primaryText
                                  : AppUi.colors(context).secondary,
                          size: 23,
                        ),
                      SizedBox(height: i == 2 ? 0 : 5),
                      Text(
                        _AppShellState.labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppUi.text(
                          fontSize: 10,
                          fontWeight:
                              i == index ? FontWeight.w700 : FontWeight.w500,
                          color:
                              i == index
                                  ? AppUi.colors(context).primaryText
                                  : AppUi.colors(context).secondary,
                        ),
                      ),
                      if (i != 2)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                i == index
                                    ? AppUi.colors(context).primaryText
                                    : Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
