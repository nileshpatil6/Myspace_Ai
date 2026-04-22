import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/ai_result.dart';
import '../constants/app_constants.dart';
import '../constants/gemini_prompts.dart';

class GeminiServiceException implements Exception {
  final String message;
  GeminiServiceException(this.message);

  @override
  String toString() => 'GeminiServiceException: $message';
}

class GeminiService {
  GeminiService(this._apiKey)
      : _dio = Dio(BaseOptions(baseUrl: AppConstants.geminiBaseUrl));

  final String _apiKey;
  final Dio _dio;

  GenerativeModel _flashModel({bool jsonMode = false}) {
    return GenerativeModel(
      model: AppConstants.geminiFlash,
      apiKey: _apiKey,
      generationConfig: jsonMode
          ? GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.1,
              maxOutputTokens: 2048,
            )
          : GenerationConfig(
              temperature: 0.3,
              maxOutputTokens: 4096,
            ),
    );
  }

  GenerativeModel _embeddingModel() {
    return GenerativeModel(
      model: AppConstants.geminiEmbedding,
      apiKey: _apiKey,
    );
  }

  // ─── Audio transcription ──────────────────────────────────────────────────

  Future<String> transcribeAudio(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final mimeType = _audioMimeType(filePath);

    Content content;

    if (bytes.length <= AppConstants.maxInlineFileSizeBytes) {
      // Inline upload for small files
      content = Content.multi([
        DataPart(mimeType, bytes),
        TextPart(GeminiPrompts.transcription),
      ]);
    } else {
      // Files API for large files
      final fileUri = await _uploadViaFilesApi(bytes, mimeType, 'audio');
      content = Content.multi([
        FilePart(Uri.parse(fileUri)),
        TextPart(GeminiPrompts.transcription),
      ]);
    }

    final model = _flashModel();
    final response = await model.generateContent([content]);
    return response.text?.trim() ?? '';
  }

  // ─── Note analysis ────────────────────────────────────────────────────────

  Future<AiNoteResult> analyzeVoiceNote(String transcript) async {
    final prompt = '${GeminiPrompts.voiceNoteAnalysis}\n$transcript';
    final model = _flashModel(jsonMode: true);
    final response = await model.generateContent([Content.text(prompt)]);
    return _parseAiResult(response.text ?? '{}');
  }

  Future<AiNoteResult> analyzeTextNote(String content) async {
    final prompt = '${GeminiPrompts.textNoteAnalysis}\n$content';
    final model = _flashModel(jsonMode: true);
    final response = await model.generateContent([Content.text(prompt)]);
    return _parseAiResult(response.text ?? '{}');
  }

  // ─── Screenshot / image analysis ─────────────────────────────────────────

  Future<AiNoteResult> analyzeScreenshot(Uint8List imageBytes) async {
    Content content;

    if (imageBytes.length <= AppConstants.maxInlineImageSizeBytes) {
      content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(GeminiPrompts.screenshotAnalysis),
      ]);
    } else {
      // Compress or upload via Files API
      final fileUri = await _uploadViaFilesApi(imageBytes, 'image/jpeg', 'image');
      content = Content.multi([
        FilePart(Uri.parse(fileUri)),
        TextPart(GeminiPrompts.screenshotAnalysis),
      ]);
    }

    final model = _flashModel(jsonMode: true);
    final response = await model.generateContent([content]);
    final result = _parseAiResult(response.text ?? '{}');
    return result;
  }

  // ─── Embeddings ───────────────────────────────────────────────────────────

  Future<List<double>> generateEmbedding(String text) async {
    final model = _embeddingModel();
    try {
      final result = await model.embedContent(
        Content.text(text),
        taskType: TaskType.retrievalDocument,
      );
      return result.embedding.values;
    } catch (e) {
      debugPrint('Embedding generation failed: $e');
      return [];
    }
  }

  Future<List<double>> generateQueryEmbedding(String query) async {
    final model = _embeddingModel();
    try {
      final result = await model.embedContent(
        Content.text(query),
        taskType: TaskType.retrievalQuery,
      );
      return result.embedding.values;
    } catch (e) {
      debugPrint('Query embedding failed: $e');
      return [];
    }
  }

  // ─── Streaming chat ───────────────────────────────────────────────────────

  Stream<String> chatStream(String userMessage, String systemPrompt) async* {
    final model = GenerativeModel(
      model: AppConstants.geminiFlash,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(systemPrompt),
    );

    final stream = model.generateContentStream([Content.text(userMessage)]);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  // ─── DateTime parsing ─────────────────────────────────────────────────────

  Future<DateTime?> parseEventDateTime(String naturalString) async {
    final now = DateTime.now();
    final prompt = '${GeminiPrompts.parseDateTime}$naturalString\n\n'
        'Current date: ${now.toIso8601String()}';

    final model = _flashModel();
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'unknown') return null;

    // Extract ISO string from response (model sometimes wraps in text)
    final isoPattern = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}');
    final match = isoPattern.firstMatch(text);
    if (match != null) {
      return DateTime.tryParse(text.substring(match.start, match.end + 3));
    }
    return DateTime.tryParse(text);
  }

  // ─── Files API upload ─────────────────────────────────────────────────────

  Future<String> _uploadViaFilesApi(
    Uint8List bytes,
    String mimeType,
    String displayNamePrefix,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.filesApiPath,
        queryParameters: {'key': _apiKey},
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: '$displayNamePrefix.${mimeType.split('/').last}',
            contentType: DioMediaType.parse(mimeType),
          ),
        }),
        options: Options(
          headers: {
            'X-Goog-Upload-Protocol': 'multipart',
          },
        ),
      );

      final fileUri = response.data?['file']?['uri'] as String?;
      if (fileUri == null) throw GeminiServiceException('Files API returned no URI');
      return fileUri;
    } catch (e) {
      throw GeminiServiceException('Files API upload failed: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AiNoteResult _parseAiResult(String jsonText) {
    try {
      // Clean up potential markdown code blocks
      var cleaned = jsonText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
        if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
        if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      final data = json.decode(cleaned.trim()) as Map<String, dynamic>;

      // Normalize event keys
      final events = (data['events'] as List? ?? []).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return AiEvent.fromJson(map);
      }).toList();

      final reminders = (data['reminders'] as List? ?? []).map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        return AiReminder.fromJson(map);
      }).toList();

      return AiNoteResult(
        title: data['title'] as String? ?? 'Untitled Note',
        summary: data['summary'] as String? ?? '',
        category: data['category'] as String? ?? 'Other',
        ocrText: data['ocr_text'] as String?,
        contentType: data['content_type'] as String?,
        events: events,
        reminders: reminders,
        keyInfo: (data['key_info'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      debugPrint('Failed to parse AI result: $e\nRaw: $jsonText');
      return const AiNoteResult(
        title: 'Untitled Note',
        summary: 'Could not process this note.',
      );
    }
  }

  String _audioMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'm4a' => 'audio/m4a',
      'mp3' => 'audio/mp3',
      'wav' => 'audio/wav',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'flac' => 'audio/flac',
      _ => 'audio/m4a',
    };
  }
}
