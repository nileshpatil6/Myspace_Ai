import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/note.dart';
import '../../../core/services/providers.dart';

// ─── Watch all notes (live stream) ────────────────────────────────────────────

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.watchNotes();
});

// ─── Search state ─────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final db = ref.watch(databaseServiceProvider);
  return db.searchNotes(query);
});

// ─── Category filter ──────────────────────────────────────────────────────────

final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

final filteredNotesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);

  if (categoryId != null) {
    return db.getNotesByCategory(categoryId);
  }
  return db.getAllNotes();
});

// ─── Recent notes ─────────────────────────────────────────────────────────────

final recentNotesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(notesStreamProvider); // Invalidate when notes change
  final db = ref.watch(databaseServiceProvider);
  return db.getRecentNotes(limit: 20);
});

// ─── Note by ID ───────────────────────────────────────────────────────────────

final noteByIdProvider = FutureProvider.autoDispose.family<Note?, int>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getNoteById(id);
});

// ─── Note count ───────────────────────────────────────────────────────────────

final noteCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notesStreamProvider);
  final db = ref.watch(databaseServiceProvider);
  return db.getNoteCount();
});

// ─── Actions ─────────────────────────────────────────────────────────────────

class NoteActions {
  static Future<void> deleteNote(WidgetRef ref, int id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteNote(id);
  }

  static Future<void> togglePin(WidgetRef ref, Note note) async {
    note.isPinned = !note.isPinned;
    note.updatedAt = DateTime.now();
    final db = ref.read(databaseServiceProvider);
    await db.saveNote(note);
  }

  static Future<void> toggleFavorite(WidgetRef ref, Note note) async {
    note.isFavorite = !note.isFavorite;
    note.updatedAt = DateTime.now();
    final db = ref.read(databaseServiceProvider);
    await db.saveNote(note);
  }

  static Future<void> archiveNote(WidgetRef ref, Note note) async {
    note.isArchived = true;
    note.updatedAt = DateTime.now();
    final db = ref.read(databaseServiceProvider);
    await db.saveNote(note);
  }
}
