import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/note.dart';
import '../../models/category.dart';
import '../../models/event_reminder.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  DatabaseService._();

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Isar? _isar;

  Future<Isar> get db async {
    _isar ??= await _open();
    return _isar!;
  }

  Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [NoteSchema, CategorySchema, EventReminderSchema],
      directory: dir.path,
      name: 'myspace_ai',
    );
  }

  // ─── Notes ────────────────────────────────────────────────────────────────

  Future<void> saveNote(Note note) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.notes.put(note);
      await note.category.save();
    });
  }

  Future<Note?> getNoteById(int id) async {
    final isar = await db;
    final note = await isar.notes.get(id);
    if (note != null) await note.category.load();
    return note;
  }

  Future<List<Note>> getAllNotes({bool includeArchived = false}) async {
    final isar = await db;
    List<Note> notes;
    if (includeArchived) {
      notes = await isar.notes
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    } else {
      notes = await isar.notes
          .filter()
          .isArchivedEqualTo(false)
          .sortByCreatedAtDesc()
          .findAll();
    }
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<List<Note>> getRecentNotes({int limit = 20}) async {
    final isar = await db;
    final notes = await isar.notes
        .filter()
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<List<Note>> getNotesByType(NoteType type) async {
    final isar = await db;
    final notes = await isar.notes
        .filter()
        .typeEqualTo(type)
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<List<Note>> getNotesByCategory(int categoryId) async {
    final isar = await db;
    final notes = await isar.notes
        .filter()
        .category((q) => q.idEqualTo(categoryId))
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return getAllNotes();
    final isar = await db;
    final q = query.trim().toLowerCase();
    final notes = await isar.notes
        .filter()
        .isArchivedEqualTo(false)
        .and()
        .group((g) => g
            .titleContains(q, caseSensitive: false)
            .or()
            .rawContentContains(q, caseSensitive: false)
            .or()
            .summaryContains(q, caseSensitive: false)
            .or()
            .richContentContains(q, caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<List<Note>> getPinnedNotes() async {
    final isar = await db;
    final notes = await isar.notes
        .filter()
        .isPinnedEqualTo(true)
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
    for (final note in notes) {
      await note.category.load();
    }
    return notes;
  }

  Future<void> deleteNote(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
  }

  Future<void> updateNoteEmbedding(int id, List<double> embedding) async {
    final isar = await db;
    final note = await isar.notes.get(id);
    if (note != null) {
      note.embeddingVector = embedding;
      await isar.writeTxn(() async {
        await isar.notes.put(note);
      });
    }
  }

  Stream<List<Note>> watchNotes() async* {
    final isar = await db;
    yield* isar.notes
        .filter()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .asyncMap((notes) async {
      for (final note in notes) {
        await note.category.load();
      }
      return notes..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<int> getNoteCount() async {
    final isar = await db;
    return isar.notes.filter().isArchivedEqualTo(false).count();
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Future<Category?> getCategoryByName(String name) async {
    final isar = await db;
    return isar.categorys
        .filter()
        .nameEqualTo(name, caseSensitive: false)
        .findFirst();
  }

  Future<Category> getOrCreateCategory(String name, {String? colorHex, bool isAi = true}) async {
    final existing = await getCategoryByName(name);
    if (existing != null) return existing;

    final category = Category()
      ..name = name
      ..colorHex = colorHex
      ..isAiGenerated = isAi
      ..isUserDefined = !isAi
      ..createdAt = DateTime.now();

    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    return category;
  }

  Future<List<Category>> getAllCategories() async {
    final isar = await db;
    return isar.categorys.where().sortByName().findAll();
  }

  Future<void> deleteCategory(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
  }

  // ─── Events & Reminders ───────────────────────────────────────────────────

  Future<void> saveEventReminder(EventReminder event) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.eventReminders.put(event);
      await event.note.save();
    });
  }

  Future<List<EventReminder>> getUpcomingEvents({int limit = 10}) async {
    final isar = await db;
    final now = DateTime.now();
    return isar.eventReminders
        .filter()
        .isCompletedEqualTo(false)
        .eventDateTimeGreaterThan(now)
        .sortByEventDateTime()
        .limit(limit)
        .findAll();
  }

  Future<void> markEventCompleted(int id) async {
    final isar = await db;
    final event = await isar.eventReminders.get(id);
    if (event != null) {
      event.isCompleted = true;
      await isar.writeTxn(() async {
        await isar.eventReminders.put(event);
      });
    }
  }

  // ─── Seed default categories ──────────────────────────────────────────────

  Future<void> seedDefaultCategories() async {
    for (final name in AppConstants.defaultCategories) {
      await getOrCreateCategory(name, isAi: false);
    }
  }
}
