import 'package:isar/isar.dart';
import 'category.dart';
import 'event_reminder.dart';

part 'note.g.dart';

enum NoteType {
  text,
  voice,
  photo,
  screenshot,
}

enum ProcessingStatus {
  pending,
  processing,
  done,
  failed,
}

@Collection()
class Note {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String uuid;

  @Index(type: IndexType.value)
  late String title;

  String? summary;

  // Raw content: transcript for voice, OCR text for screenshot, null for text/photo
  String? rawContent;

  // Rich/user-editable content (markdown for text notes)
  String? richContent;

  @Enumerated(EnumType.ordinal)
  late NoteType type;

  @Enumerated(EnumType.ordinal)
  ProcessingStatus processingStatus = ProcessingStatus.done;

  // File paths (relative to app documents directory)
  String? audioFilePath;
  String? imageFilePath;

  // AI-generated embedding for semantic search (768-dim from text-embedding-004)
  List<double>? embeddingVector;

  // Timestamps
  @Index(type: IndexType.value)
  late DateTime createdAt;

  late DateTime updatedAt;

  // Flags
  bool isPinned = false;
  bool isArchived = false;
  bool isFavorite = false;

  // Category link (many-to-one)
  final category = IsarLink<Category>();

  // Event reminders backlink
  @Backlink(to: 'note')
  final events = IsarLinks<EventReminder>();

  // Helper: display content (fallback chain)
  @ignore
  String get displayContent =>
      summary ?? rawContent ?? richContent ?? 'No content';

  @ignore
  String get typeLabel => switch (type) {
        NoteType.text => 'Text',
        NoteType.voice => 'Voice',
        NoteType.photo => 'Photo',
        NoteType.screenshot => 'Screenshot',
      };
}
