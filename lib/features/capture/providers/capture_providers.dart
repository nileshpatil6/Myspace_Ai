import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/note.dart';
import '../../../models/event_reminder.dart';
import '../../../models/ai_result.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

sealed class CaptureState {
  const CaptureState();
}

class CaptureIdle extends CaptureState {
  const CaptureIdle();
}

class CaptureRecording extends CaptureState {
  const CaptureRecording();
}

class CaptureProcessing extends CaptureState {
  const CaptureProcessing({required this.message});
  final String message;
}

class CaptureDone extends CaptureState {
  const CaptureDone({required this.note});
  final Note note;
}

class CaptureError extends CaptureState {
  const CaptureError({required this.message});
  final String message;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CaptureNotifier extends StateNotifier<CaptureState> {
  CaptureNotifier(this._ref) : super(const CaptureIdle());

  final Ref _ref;
  final _recorder = AudioRecorder();
  static const _uuid = Uuid();
  String? _currentRecordingPath;

  bool get isRecording => state is CaptureRecording;

  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      final dir = await getTemporaryDirectory();
      _currentRecordingPath = '${dir.path}/${_uuid.v4()}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      state = const CaptureRecording();
      return true;
    } catch (e) {
      state = CaptureError(message: 'Failed to start recording: $e');
      return false;
    }
  }

  Future<Note?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null) {
        state = const CaptureIdle();
        return null;
      }

      return await _processVoiceFile(path);
    } catch (e) {
      state = CaptureError(message: 'Recording failed: $e');
      return null;
    }
  }

  Future<Note?> _processVoiceFile(String audioPath) async {
    final gemini = _ref.read(geminiServiceProvider);
    final storage = _ref.read(storageServiceProvider);
    final db = _ref.read(databaseServiceProvider);

    if (gemini == null) {
      state = const CaptureError(message: 'Gemini API key not configured. Go to Settings.');
      return null;
    }

    state = const CaptureProcessing(message: 'Transcribing audio...');
    String transcript = '';

    try {
      transcript = await gemini.transcribeAudio(audioPath);
    } catch (e) {
      state = CaptureError(message: 'Transcription failed: $e');
      return null;
    }

    state = const CaptureProcessing(message: 'Analyzing content...');
    AiNoteResult aiResult;
    try {
      aiResult = await gemini.analyzeVoiceNote(transcript);
    } catch (e) {
      // If analysis fails, still save with transcript
      aiResult = AiNoteResult(
        title: 'Voice Note',
        summary: transcript.length > 200 ? '${transcript.substring(0, 200)}...' : transcript,
        rawTranscript: transcript,
      );
    }

    state = const CaptureProcessing(message: 'Saving note...');

    // Save audio file to permanent storage
    final relAudioPath = await storage.saveAudioFile(audioPath);

    // Get or create category
    final category = await db.getOrCreateCategory(aiResult.category);

    // Build note
    final note = Note()
      ..uuid = _uuid.v4()
      ..title = aiResult.title
      ..summary = aiResult.summary
      ..rawContent = transcript
      ..type = NoteType.voice
      ..processingStatus = ProcessingStatus.done
      ..audioFilePath = relAudioPath
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    note.category.value = category;
    await db.saveNote(note);

    // Schedule reminders
    await _scheduleReminders(aiResult.reminders, note);

    // Schedule event notifications
    await _scheduleEvents(aiResult.events, note, db);

    // Generate embedding in background
    _generateEmbeddingAsync(note);

    state = CaptureDone(note: note);
    return note;
  }

  Future<void> processScreenshot(String screenshotPath) async {
    final gemini = _ref.read(geminiServiceProvider);
    final storage = _ref.read(storageServiceProvider);
    final db = _ref.read(databaseServiceProvider);

    if (gemini == null) {
      state = const CaptureError(message: 'Gemini API key not configured.');
      return;
    }

    state = const CaptureProcessing(message: 'Analyzing screenshot...');

    try {
      final bytes = await File(screenshotPath).readAsBytes();
      final aiResult = await gemini.analyzeScreenshot(bytes);

      state = const CaptureProcessing(message: 'Saving screenshot...');
      final relPath = await storage.saveScreenshotFromPath(screenshotPath);
      final category = await db.getOrCreateCategory(aiResult.category);

      final note = Note()
        ..uuid = const Uuid().v4()
        ..title = aiResult.title
        ..summary = aiResult.summary
        ..rawContent = aiResult.ocrText
        ..type = NoteType.screenshot
        ..processingStatus = ProcessingStatus.done
        ..imageFilePath = relPath
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      note.category.value = category;
      await db.saveNote(note);

      await _scheduleEvents(aiResult.events, note, db);
      _generateEmbeddingAsync(note);

      state = CaptureDone(note: note);
    } catch (e) {
      state = CaptureError(message: 'Failed to process screenshot: $e');
    }
  }

  Future<Note?> saveTextNote({
    required String title,
    required String content,
    String? categoryName,
  }) async {
    final gemini = _ref.read(geminiServiceProvider);
    final db = _ref.read(databaseServiceProvider);

    state = const CaptureProcessing(message: 'Saving note...');

    AiNoteResult? aiResult;
    if (gemini != null && content.length > 20) {
      try {
        aiResult = await gemini.analyzeTextNote(content);
      } catch (_) {
        // Optional enrichment — continue without it
      }
    }

    final effectiveTitle = title.isEmpty ? (aiResult?.title ?? 'Note') : title;
    final effectiveCategory = categoryName ?? aiResult?.category ?? 'Personal';
    final category = await db.getOrCreateCategory(effectiveCategory);

    final note = Note()
      ..uuid = _uuid.v4()
      ..title = effectiveTitle
      ..summary = aiResult?.summary
      ..richContent = content
      ..type = NoteType.text
      ..processingStatus = ProcessingStatus.done
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    note.category.value = category;
    await db.saveNote(note);

    if (aiResult != null) {
      await _scheduleReminders(aiResult.reminders, note);
      await _scheduleEvents(aiResult.events, note, db);
    }

    _generateEmbeddingAsync(note);
    state = CaptureDone(note: note);
    return note;
  }

  Future<Note?> savePhotoNote(Uint8List imageBytes, {String? userNote}) async {
    final gemini = _ref.read(geminiServiceProvider);
    final storage = _ref.read(storageServiceProvider);
    final db = _ref.read(databaseServiceProvider);

    state = const CaptureProcessing(message: 'Analyzing photo...');

    AiNoteResult? aiResult;
    if (gemini != null) {
      try {
        aiResult = await gemini.analyzeScreenshot(imageBytes);
      } catch (_) {}
    }

    state = const CaptureProcessing(message: 'Saving photo...');
    final relPath = await storage.saveImageBytes(imageBytes);
    final category = await db.getOrCreateCategory(aiResult?.category ?? 'Personal');

    final note = Note()
      ..uuid = _uuid.v4()
      ..title = aiResult?.title ?? 'Photo Note'
      ..summary = aiResult?.summary ?? userNote
      ..richContent = userNote
      ..type = NoteType.photo
      ..processingStatus = ProcessingStatus.done
      ..imageFilePath = relPath
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    note.category.value = category;
    await db.saveNote(note);
    _generateEmbeddingAsync(note);

    state = CaptureDone(note: note);
    return note;
  }

  Future<void> _scheduleReminders(List<AiReminder> reminders, Note note) async {
    final gemini = _ref.read(geminiServiceProvider);
    if (gemini == null) return;

    for (final reminder in reminders) {
      final dt = await gemini.parseEventDateTime(reminder.datetimeNatural);
      if (dt == null) continue;

      await NotificationService.instance.scheduleVoiceReminder(
        task: reminder.task,
        scheduledAt: dt,
        noteId: note.uuid,
      );
    }
  }

  Future<void> _scheduleEvents(
    List<AiEvent> events,
    Note note,
    DatabaseService db,
  ) async {
    final gemini = _ref.read(geminiServiceProvider);
    if (gemini == null) return;

    for (final event in events) {
      final dt = await gemini.parseEventDateTime(event.eventDatetimeNatural);
      if (dt == null) continue;

      final reminder = EventReminder()
        ..uuid = const Uuid().v4()
        ..eventName = event.eventName
        ..location = event.location
        ..eventDateTime = dt
        ..naturalDateString = event.eventDatetimeNatural
        ..createdAt = DateTime.now();

      reminder.note.value = note;
      await db.saveEventReminder(reminder);

      final ids = await NotificationService.instance
          .scheduleEventNotifications(reminder);
      reminder.notificationIds = ids;
      await db.saveEventReminder(reminder);
    }
  }

  void _generateEmbeddingAsync(Note note) {
    final embeddingService = _ref.read(embeddingServiceProvider);
    if (embeddingService == null) return;

    Future.microtask(() async {
      try {
        final embedding = await embeddingService.generateNoteEmbedding(note);
        if (embedding.isNotEmpty) {
          await DatabaseService.instance.updateNoteEmbedding(note.id, embedding);
        }
      } catch (e) {
        debugPrint('Embedding generation failed: $e');
      }
    });
  }

  void reset() {
    state = const CaptureIdle();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(ref);
});
