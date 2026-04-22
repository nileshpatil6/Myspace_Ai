import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/capture_providers.dart';
import '../../../widgets/orange_button.dart';
import 'widgets/pulse_ring_painter.dart';

class VoiceOverlayScreen extends ConsumerStatefulWidget {
  const VoiceOverlayScreen({super.key});

  @override
  ConsumerState<VoiceOverlayScreen> createState() => _VoiceOverlayScreenState();
}

class _VoiceOverlayScreenState extends ConsumerState<VoiceOverlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _ring1Controller;
  late AnimationController _ring2Controller;
  late AnimationController _ring3Controller;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  final RecorderController _recorderController = RecorderController();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    const duration = Duration(milliseconds: 2200);
    _ring1Controller = AnimationController(vsync: this, duration: duration)..repeat();
    _ring2Controller = AnimationController(vsync: this, duration: duration)
      ..forward(from: 0.33)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _ring2Controller.repeat();
      });
    _ring3Controller = AnimationController(vsync: this, duration: duration)
      ..forward(from: 0.66)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _ring3Controller.repeat();
      });

    _ring1 = CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut);
    _ring2 = CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut);
    _ring3 = CurvedAnimation(parent: _ring3Controller, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  Future<void> _startRecording() async {
    final notifier = ref.read(captureProvider.notifier);
    final success = await notifier.startRecording();
    if (!success) {
      if (mounted) context.pop();
      return;
    }

    await _recorderController.record();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = _stopwatch.elapsed;
        });
      }
    });
    if (mounted) setState(() => _started = true);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _stopwatch.stop();
    _recorderController.stop();

    final note = await ref.read(captureProvider.notifier).stopRecording();
    if (mounted) {
      context.pop(note);
    }
  }

  @override
  void dispose() {
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    _timer?.cancel();
    _recorderController.dispose();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final isProcessing = captureState is CaptureProcessing;
    final processingMsg = captureState is CaptureProcessing ? captureState.message : '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xF00A0A0A),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              AppColors.orange.withAlpha(40),
              const Color(0xF00A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Pulse rings behind everything
              Positioned.fill(
                child: CustomPaint(
                  painter: PulseRingPainter(
                    animation1: _ring1,
                    animation2: _ring2,
                    animation3: _ring3,
                  ),
                ),
              ),

              // Close button top-right
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    _stopwatch.stop();
                    _recorderController.stop();
                    ref.read(captureProvider.notifier).reset();
                    context.pop();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),

              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Status label
                  Text(
                    isProcessing ? processingMsg : (_started ? 'Listening...' : 'Starting...'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: Colors.white.withAlpha(153),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // Timer
                  Text(
                    isProcessing ? '' : _timerText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 52,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      color: Colors.white,
                      height: 1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),

                  // Waveform
                  if (_started && !isProcessing)
                    SizedBox(
                      height: 70,
                      child: AudioWaveforms(
                        recorderController: _recorderController,
                        size: Size(MediaQuery.of(context).size.width * 0.8, 70),
                        waveStyle: WaveStyle(
                          waveColor: AppColors.orange,
                          showMiddleLine: false,
                          extendWaveform: true,
                          waveCap: StrokeCap.round,
                          spacing: 7,
                          waveThickness: 2.5,
                          scaleFactor: 100,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                  if (isProcessing)
                    const SizedBox(
                      height: 70,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),

                  // Stop button
                  if (!isProcessing)
                    OrangeButton(
                      label: 'Tap to Stop',
                      onPressed: _stopRecording,
                      height: 56,
                      fontSize: 16,
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
