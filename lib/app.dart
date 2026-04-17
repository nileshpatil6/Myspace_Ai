import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/services/native_bridge_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/capture/presentation/voice_overlay_screen.dart';
import 'features/capture/presentation/screenshot_preview_screen.dart';
import 'features/categories/presentation/categories_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/notes/presentation/notes_list_screen.dart';
import 'features/notes/presentation/note_detail_screen.dart';
import 'features/notes/presentation/note_editor_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

// ─── Router ────────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Bottom-nav shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            _AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/notes', builder: (_, __) => const NotesListScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        ],
      ),

      // Note detail / editor (full-screen, above shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notes/new',
        builder: (_, __) => const NoteEditorScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notes/:id',
        builder: (_, state) =>
            NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
      ),

      // Voice overlay (transparent / fade-in)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/capture/voice',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 350),
          child: const VoiceOverlayScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Screenshot preview
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/capture/screenshot',
        builder: (_, state) => ScreenshotPreviewScreen(
          screenshotPath: state.extra as String,
        ),
      ),

      // Settings
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});

// ─── App shell with bottom nav ─────────────────────────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _selectedIndex = 0;

  static const _tabs = ['/', '/notes', '/chat', '/categories'];

  @override
  void initState() {
    super.initState();
    _listenNativeEvents();
  }

  void _listenNativeEvents() {
    final native = NativeBridgeService.instance;

    native.powerButtonEvents.listen((event) {
      if (!mounted) return;
      if (event == 'VOICE_TRIGGER') {
        context.push('/capture/voice');
      }
    });

    native.screenshotEvents.listen((path) {
      if (!mounted) return;
      context.push('/capture/screenshot', extra: path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: _selectedIndex == 0,
                  onTap: () => _goTo(0),
                ),
                _NavItem(
                  icon: Icons.notes_rounded,
                  label: 'Notes',
                  selected: _selectedIndex == 1,
                  onTap: () => _goTo(1),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  selected: _selectedIndex == 2,
                  onTap: () => _goTo(2),
                ),
                _NavItem(
                  icon: Icons.folder_rounded,
                  label: 'Categories',
                  selected: _selectedIndex == 3,
                  onTap: () => _goTo(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goTo(int index) {
    setState(() => _selectedIndex = index);
    context.go(_tabs[index]);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange.withAlpha(25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.orange : AppColors.darkTextDisabled,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.orange : AppColors.darkTextDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Root App widget ───────────────────────────────────────────────────────────

class MyspaceApp extends ConsumerWidget {
  const MyspaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Myspace AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
