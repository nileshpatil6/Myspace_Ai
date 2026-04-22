import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/note.dart';
import 'gemini_service.dart';

class EmbeddingService {
  EmbeddingService(this._geminiService);

  final GeminiService _geminiService;

  /// Finds the most semantically similar notes to [query].
  /// Uses cosine similarity in a background Isolate to avoid jank.
  Future<List<Note>> findSimilarNotes(
    String query,
    List<Note> allNotes, {
    int topK = 15,
  }) async {
    final notesWithEmbeddings = allNotes
        .where((n) => n.embeddingVector != null && n.embeddingVector!.isNotEmpty)
        .toList();

    if (notesWithEmbeddings.isEmpty) {
      // Fall back to returning all notes if none have embeddings
      return allNotes.take(topK).toList();
    }

    try {
      final queryEmbedding = await _geminiService.generateQueryEmbedding(query);
      if (queryEmbedding.isEmpty) return notesWithEmbeddings.take(topK).toList();

      // Run similarity computation in an isolate to avoid blocking UI
      final scored = await Isolate.run(() {
        return _computeSimilarities(queryEmbedding, notesWithEmbeddings);
      });

      scored.sort((a, b) => b.$2.compareTo(a.$2));
      return scored.take(topK).map((e) => e.$1).toList();
    } catch (e) {
      debugPrint('Semantic search failed, falling back to all notes: $e');
      return allNotes.take(topK).toList();
    }
  }

  static List<(Note, double)> _computeSimilarities(
    List<double> queryEmbedding,
    List<Note> notes,
  ) {
    return notes.map((note) {
      final sim = cosineSimilarity(queryEmbedding, note.embeddingVector!);
      return (note, sim);
    }).toList();
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denom = sqrt(normA) * sqrt(normB);
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  /// Generates and stores an embedding for a note's content in the background.
  Future<List<double>> generateNoteEmbedding(Note note) async {
    final textToEmbed = [
      note.title,
      if (note.summary != null) note.summary!,
      if (note.rawContent != null) note.rawContent!,
      if (note.richContent != null) note.richContent!,
    ].join(' ');

    if (textToEmbed.trim().isEmpty) return [];
    return _geminiService.generateEmbedding(textToEmbed);
  }
}
