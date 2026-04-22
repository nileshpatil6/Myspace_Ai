import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/note.dart';

class NoteCard extends ConsumerWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.animationIndex = 0,
  });

  final Note note;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NoteTypeBadge(type: note.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (note.isPinned)
                          Icon(Icons.push_pin_rounded,
                              size: 14, color: AppColors.orange.withAlpha(180)),
                      ],
                    ),
                    if (note.displayContent.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.displayContent,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((note.type == NoteType.photo || note.type == NoteType.screenshot) &&
                        note.imageFilePath != null)
                      _NoteImageThumb(relPath: note.imageFilePath!),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (note.category.value != null)
                          NoteCategoryChip(
                            name: note.category.value!.name,
                            colorHex: note.category.value!.colorHex,
                          ),
                        const Spacer(),
                        Text(
                          _formatTime(note.createdAt),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: textSecondary.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class NoteTypeBadge extends StatelessWidget {
  const NoteTypeBadge({super.key, required this.type});
  final NoteType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NoteType.voice => (Icons.mic_rounded, const Color(0xFF9B59B6)),
      NoteType.photo => (Icons.image_rounded, const Color(0xFF3498DB)),
      NoteType.screenshot => (Icons.screenshot_rounded, const Color(0xFF1ABC9C)),
      NoteType.text => (Icons.notes_rounded, const Color(0xFF95A5A6)),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class NoteCategoryChip extends StatelessWidget {
  const NoteCategoryChip({super.key, required this.name, this.colorHex});
  final String name;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    var chipColor = AppColors.categoryColors[name] ?? AppColors.orange;
    if (colorHex != null && AppColors.categoryColors[name] == null) {
      try {
        chipColor = Color(int.parse('FF${colorHex!.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
    );
  }
}

class _NoteImageThumb extends StatefulWidget {
  const _NoteImageThumb({required this.relPath});
  final String relPath;

  @override
  State<_NoteImageThumb> createState() => _NoteImageThumbState();
}

class _NoteImageThumbState extends State<_NoteImageThumb> {
  String? _fullPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final base = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _fullPath = p.join(base.path, widget.relPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fullPath == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(File(_fullPath!)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
