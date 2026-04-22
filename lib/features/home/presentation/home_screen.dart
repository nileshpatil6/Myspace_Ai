import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../features/capture/providers/capture_providers.dart';
import '../../../features/notes/providers/notes_providers.dart';
import '../../../models/event_reminder.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../../../widgets/orange_button.dart';
import '../../notes/presentation/widgets/note_card.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _fabExpanded = false;
  late AnimationController _fabController;
  late Animation<double> _fabRotation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
    if (_fabExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  Future<void> _pickPhoto() async {
    _toggleFab();
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    if (!mounted) return;
    await ref.read(captureProvider.notifier).savePhotoNote(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final recentAsync = ref.watch(recentNotesProvider);
    final noteCountAsync = ref.watch(noteCountProvider);
    final catCountAsync = ref.watch(categoriesCountProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return GradientScaffold(
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                expandedHeight: 0,
                toolbarHeight: 64,
                title: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.orangeAccent.createShader(bounds),
                      child: const Text(
                        'Myspace',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      ' AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date greeting
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _StatCard(
                            label: 'Notes',
                            value: noteCountAsync.when(
                              data: (c) => '$c',
                              loading: () => '—',
                              error: (_, __) => '—',
                            ),
                            icon: Icons.notes_rounded,
                            color: const Color(0xFF3498DB),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Categories',
                            value: catCountAsync.when(
                              data: (c) => '$c',
                              loading: () => '—',
                              error: (_, __) => '—',
                            ),
                            icon: Icons.folder_rounded,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Events',
                            value: eventsAsync.when(
                              data: (e) => '${e.length}',
                              loading: () => '—',
                              error: (_, __) => '—',
                            ),
                            icon: Icons.event_rounded,
                            color: const Color(0xFF2ECC71),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 20),

                      // Quick actions
                      _QuickActionsRow(
                        onVoice: () => context.push('/capture/voice'),
                        onText: () => context.push('/notes/new'),
                        onPhoto: _pickPhoto,
                        onChat: () => context.push('/chat'),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 20),

                      // Upcoming events
                      eventsAsync.when(
                        data: (events) => events.isEmpty
                            ? const SizedBox.shrink()
                            : _UpcomingSection(events: events),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 8),

                      // Recent notes header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/notes'),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.orange,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent notes list
              recentAsync.when(
                data: (notes) => notes.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyStateWidget(
                          icon: Icons.mic_rounded,
                          title: 'Your memory is empty',
                          subtitle: 'Long-press the floating button or tap Voice to capture your first note',
                          action: () => context.push('/capture/voice'),
                          actionLabel: 'Record Voice Note',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => NoteCard(
                              note: notes[i],
                              animationIndex: i,
                              onTap: () => context.push('/notes/${notes[i].id}'),
                            ),
                            childCount: notes.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('$e')),
                ),
              ),
            ],
          ),

          // FAB speed dial
          Positioned(
            bottom: 24,
            right: 20,
            child: _SpeedDial(
              expanded: _fabExpanded,
              rotation: _fabRotation,
              onToggle: _toggleFab,
              onText: () {
                _toggleFab();
                context.push('/notes/new');
              },
              onVoice: () {
                _toggleFab();
                context.push('/capture/voice');
              },
              onPhoto: _pickPhoto,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$greeting • ${DateFormat('EEEE, MMM d').format(DateTime.now())}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onVoice,
    required this.onText,
    required this.onPhoto,
    required this.onChat,
  });
  final VoidCallback onVoice;
  final VoidCallback onText;
  final VoidCallback onPhoto;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(icon: Icons.mic_rounded, label: 'Voice', color: const Color(0xFF9B59B6), onTap: onVoice),
        const SizedBox(width: 10),
        _QuickAction(icon: Icons.edit_rounded, label: 'Text', color: const Color(0xFF3498DB), onTap: onText),
        const SizedBox(width: 10),
        _QuickAction(icon: Icons.image_rounded, label: 'Photo', color: const Color(0xFF2ECC71), onTap: onPhoto),
        const SizedBox(width: 10),
        _QuickAction(icon: Icons.chat_bubble_rounded, label: 'Chat', color: AppColors.orange, onTap: onChat),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 25 : 18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.events});
  final List<EventReminder> events;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final ev = events[i];
              final daysLeft = ev.eventDateTime.difference(DateTime.now()).inDays;
              return GlassCard(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ev.eventName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 11, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            daysLeft == 0
                                ? 'Today'
                                : daysLeft == 1
                                    ? 'Tomorrow'
                                    : 'In $daysLeft days',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({
    required this.expanded,
    required this.rotation,
    required this.onToggle,
    required this.onText,
    required this.onVoice,
    required this.onPhoto,
  });
  final bool expanded;
  final Animation<double> rotation;
  final VoidCallback onToggle;
  final VoidCallback onText;
  final VoidCallback onVoice;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (expanded) ...[
          _MiniAction(icon: Icons.image_rounded, label: 'Photo', onTap: onPhoto),
          const SizedBox(height: 8),
          _MiniAction(icon: Icons.mic_rounded, label: 'Voice', onTap: onVoice),
          const SizedBox(height: 8),
          _MiniAction(icon: Icons.edit_rounded, label: 'Text', onTap: onText),
          const SizedBox(height: 12),
        ],
        RotationTransition(
          turns: rotation,
          child: OrangeIconButton(
            icon: Icons.add_rounded,
            onPressed: onToggle,
            size: 58,
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6)],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6)],
          ),
          child: Icon(icon, size: 20, color: AppColors.orange),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.3, end: 0);
  }
}
