import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../../../widgets/orange_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;
  bool _serviceRunning = false;
  bool _floatingButtonEnabled = false;
  bool _hasOverlay = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: AppConstants.geminiApiKeyStorageKey);
    final native = NativeBridgeService.instance;
    final running = await native.isServiceRunning();
    final overlay = await native.hasOverlayPermission();

    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _serviceRunning = running;
        _hasOverlay = overlay;
        _floatingButtonEnabled = overlay && running;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(
      key: AppConstants.geminiApiKeyStorageKey,
      value: _apiKeyController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final themeMode = ref.watch(themeProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── API Key ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Gemini API', textColor: textSecondary),
          GlassCard(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API Key',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_apiKeyVisible,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'AIza...',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _apiKeyVisible = !_apiKeyVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OrangeButton(
                  label: 'Save API Key',
                  onPressed: _saveApiKey,
                  height: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get a free API key at aistudio.google.com',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ─── Theme ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance', textColor: textSecondary),
          GlassCard(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ThemeOption(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                    const SizedBox(width: 10),
                    _ThemeOption(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 10),
                    _ThemeOption(
                      label: 'System',
                      icon: Icons.brightness_auto_rounded,
                      selected: themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Trigger service ──────────────────────────────────────────────
          _SectionHeader(title: 'Triggers', textColor: textSecondary),
          GlassCard(
            padding: const EdgeInsets.all(0),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _PermTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessibility Service',
                  subtitle: 'Enables power button voice trigger',
                  status: _serviceRunning ? 'Active' : 'Inactive',
                  statusOk: _serviceRunning,
                  isDark: isDark,
                  onTap: () async {
                    await NativeBridgeService.instance.openAccessibilitySettings();
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                _PermTile(
                  icon: Icons.bubble_chart_rounded,
                  title: 'Floating Button',
                  subtitle: 'Orange bubble to trigger voice (all devices)',
                  status: _floatingButtonEnabled ? 'Enabled' : 'Disabled',
                  statusOk: _floatingButtonEnabled,
                  isDark: isDark,
                  onTap: () async {
                    final native = NativeBridgeService.instance;
                    if (!_hasOverlay) {
                      await native.requestOverlayPermission();
                    } else if (_floatingButtonEnabled) {
                      await native.hideFloatingButton();
                      setState(() => _floatingButtonEnabled = false);
                    } else {
                      await native.startService();
                      await native.showFloatingButton();
                      setState(() {
                        _floatingButtonEnabled = true;
                        _serviceRunning = true;
                      });
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                _PermTile(
                  icon: Icons.screenshot_monitor_rounded,
                  title: 'Screenshot Watcher',
                  subtitle: 'Auto-process screenshots (Vol+Power)',
                  status: _serviceRunning ? 'Active' : 'Inactive',
                  statusOk: _serviceRunning,
                  isDark: isDark,
                  onTap: () async {
                    final native = NativeBridgeService.instance;
                    if (_serviceRunning) {
                      await native.stopService();
                      setState(() => _serviceRunning = false);
                    } else {
                      await native.startService();
                      setState(() => _serviceRunning = true);
                    }
                  },
                ),
              ],
            ),
          ),

          // ─── Permissions ─────────────────────────────────────────────────
          _SectionHeader(title: 'Permissions', textColor: textSecondary),
          GlassCard(
            padding: const EdgeInsets.all(0),
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                _PermissionRow(
                  icon: Icons.mic_rounded,
                  label: 'Microphone',
                  permission: Permission.microphone,
                  isDark: isDark,
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                _PermissionRow(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo Library',
                  permission: Permission.photos,
                  isDark: isDark,
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                _PermissionRow(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  permission: Permission.notification,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.darkSurfaceBorder,
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.darkTextSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  const _PermTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusOk,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final bool statusOk;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListTile(
      leading: Icon(icon, color: AppColors.orange, size: 22),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary)),
      subtitle: Text(subtitle,
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (statusOk ? AppColors.success : AppColors.error).withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: statusOk ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _PermissionRow extends StatefulWidget {
  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.permission,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Permission permission;
  final bool isDark;

  @override
  State<_PermissionRow> createState() => _PermissionRowState();
}

class _PermissionRowState extends State<_PermissionRow> {
  PermissionStatus _status = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final status = await widget.permission.status;
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final ok = _status.isGranted;

    return ListTile(
      leading: Icon(widget.icon, color: AppColors.orange, size: 22),
      title: Text(widget.label,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary)),
      trailing: ok
          ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
          : TextButton(
              onPressed: () async {
                await widget.permission.request();
                await _check();
              },
              child: const Text('Grant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  )),
            ),
    );
  }
}
