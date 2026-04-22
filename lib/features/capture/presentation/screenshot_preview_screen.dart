import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/orange_button.dart';
import '../../../widgets/glass_card.dart';
import '../providers/capture_providers.dart';

class ScreenshotPreviewScreen extends ConsumerStatefulWidget {
  const ScreenshotPreviewScreen({super.key, required this.screenshotPath});

  final String screenshotPath;

  @override
  ConsumerState<ScreenshotPreviewScreen> createState() =>
      _ScreenshotPreviewScreenState();
}

class _ScreenshotPreviewScreenState
    extends ConsumerState<ScreenshotPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(captureProvider.notifier)
          .processScreenshot(widget.screenshotPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captureState = ref.watch(captureProvider);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Screenshot'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(captureProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screenshot preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.screenshotPath),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Processing state / results
            if (captureState is CaptureProcessing)
              _buildShimmerCard(isDark)
            else if (captureState is CaptureDone)
              _buildResultCard(captureState.note.title,
                  captureState.note.summary, textPrimary, textSecondary)
            else if (captureState is CaptureError)
              _buildErrorCard(captureState.message),

            const SizedBox(height: 20),

            if (captureState is CaptureDone)
              OrangeButton(
                label: 'Done',
                expanded: true,
                onPressed: () {
                  ref.read(captureProvider.notifier).reset();
                  context.go('/notes');
                },
              ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E0D8),
      highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F0EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 180, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Container(height: 14, width: double.infinity, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 14, width: 260, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Text('Analyzing screenshot...', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultCard(
      String title, String? summary, Color textPrimary, Color textSecondary) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.orange, size: 16),
              const SizedBox(width: 8),
              Text('AI Analysis', style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary, style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 14),
              const SizedBox(width: 6),
              Text('Saved to Notes', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildErrorCard(String message) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }
}
