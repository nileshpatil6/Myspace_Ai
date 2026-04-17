import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/note.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../providers/notes_providers.dart';
import 'widgets/note_card.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});
  final int noteId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _initAudio(String relPath) async {
    final base = await getApplicationDocumentsDirectory();
    final fullPath = p.join(base.path, relPath);
    await _player.setFilePath(fullPath);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteAsync = ref.watch(noteByIdProvider(widget.noteId));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return const Scaffold(body: Center(child: Text('Note not found')));
        }
        return _buildDetail(context, note, isDark);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Note note, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GradientScaffold(
      appBar: AppBar(
        title: NoteTypeBadge(type: note.type),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'pin') {
                await NoteActions.togglePin(ref, note);
              } else if (val == 'delete') {
                final confirm = await _confirmDelete(context);
                if (confirm == true && context.mounted) {
                  await NoteActions.deleteNote(ref, note.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pin',
                child: Text(note.isPinned ? 'Unpin' : 'Pin'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              note.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                height: 1.2,
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 8),

            // Meta row
            Row(
              children: [
                if (note.category.value != null)
                  NoteCategoryChip(
                    name: note.category.value!.name,
                    colorHex: note.category.value!.colorHex,
                  ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(note.createdAt),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: textSecondary.withAlpha(150),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // Audio player
            if (note.type == NoteType.voice && note.audioFilePath != null)
              _AudioPlayerCard(
                relPath: note.audioFilePath!,
                player: _player,
                isPlaying: _isPlaying,
                position: _position,
                duration: _duration,
                onInit: () => _initAudio(note.audioFilePath!),
                onToggle: () {
                  if (_isPlaying) {
                    _player.pause();
                  } else {
                    _player.play();
                  }
                },
                onSeek: (val) => _player.seek(val),
                isDark: isDark,
              ).animate().fadeIn(delay: 150.ms),

            // Image
            if ((note.type == NoteType.photo || note.type == NoteType.screenshot) &&
                note.imageFilePath != null)
              _FullImage(relPath: note.imageFilePath!)
                  .animate()
                  .fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            // Summary section
            if (note.summary != null && note.summary!.isNotEmpty)
              _Section(
                label: 'Summary',
                icon: Icons.auto_awesome_rounded,
                isDark: isDark,
                textPrimary: textPrimary,
                child: Text(
                  note.summary!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

            // Rich content / transcript
            if (note.richContent != null && note.richContent!.isNotEmpty)
              _Section(
                label: note.type == NoteType.text ? 'Note' : 'Transcript',
                icon: Icons.article_rounded,
                isDark: isDark,
                textPrimary: textPrimary,
                child: MarkdownBody(
                  data: note.richContent ?? note.rawContent ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

            if (note.rawContent != null &&
                note.rawContent!.isNotEmpty &&
                note.richContent == null)
              _Section(
                label: note.type == NoteType.voice ? 'Transcript' : 'Extracted Text',
                icon: Icons.text_fields_rounded,
                isDark: isDark,
                textPrimary: textPrimary,
                child: Text(
                  note.rawContent!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.child,
    required this.isDark,
    required this.textPrimary,
  });
  final String label;
  final IconData icon;
  final Widget child;
  final bool isDark;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.orange,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  const _AudioPlayerCard({
    required this.relPath,
    required this.player,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onInit,
    required this.onToggle,
    required this.onSeek,
    required this.isDark,
  });
  final String relPath;
  final AudioPlayer player;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onInit;
  final VoidCallback onToggle;
  final void Function(Duration) onSeek;
  final bool isDark;

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    final cur = widget.position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C54), Color(0xFFFF5A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 2,
                    activeTrackColor: AppColors.orange,
                    inactiveTrackColor: AppColors.orange.withAlpha(40),
                    thumbColor: AppColors.orange,
                  ),
                  child: Slider(
                    value: cur,
                    min: 0,
                    max: max > 0 ? max : 1,
                    onChanged: (v) => widget.onSeek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(widget.position),
                        style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)),
                    Text(_fmt(widget.duration),
                        style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullImage extends StatefulWidget {
  const _FullImage({required this.relPath});
  final String relPath;

  @override
  State<_FullImage> createState() => _FullImageState();
}

class _FullImageState extends State<_FullImage> {
  String? _fullPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final base = await getApplicationDocumentsDirectory();
    if (mounted) setState(() => _fullPath = p.join(base.path, widget.relPath));
  }

  @override
  Widget build(BuildContext context) {
    if (_fullPath == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(_fullPath!), width: double.infinity, fit: BoxFit.cover),
    );
  }
}
