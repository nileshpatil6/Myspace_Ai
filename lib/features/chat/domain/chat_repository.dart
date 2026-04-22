import '../../../core/constants/app_constants.dart';
import '../../../core/constants/gemini_prompts.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/embedding_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../models/note.dart';

class ChatRepository {
  ChatRepository({
    required this.geminiService,
    required this.databaseService,
    required this.embeddingService,
  });

  final GeminiService geminiService;
  final DatabaseService databaseService;
  final EmbeddingService? embeddingService;

  Stream<String> chat(String userMessage) async* {
    final allNotes = await databaseService.getAllNotes();

    List<Note> contextNotes;
    if (allNotes.length <= AppConstants.maxNotesInChatContext) {
      contextNotes = allNotes;
    } else if (embeddingService != null) {
      contextNotes = await embeddingService!.findSimilarNotes(
        userMessage,
        allNotes,
        topK: AppConstants.chatTopKNotes,
      );
    } else {
      contextNotes = allNotes.take(AppConstants.chatTopKNotes).toList();
    }

    final contextLines = contextNotes.map((n) {
      final type = n.type.name.toUpperCase();
      final category = n.category.value?.name ?? 'General';
      final content = n.summary ?? n.rawContent ?? n.richContent ?? '';
      return '[$type | $category] ${n.title}: $content';
    }).join('\n\n');

    final systemPrompt = GeminiPrompts.chatSystemPrompt(
      contextLines.isEmpty ? 'No notes saved yet.' : contextLines,
    );

    yield* geminiService.chatStream(userMessage, systemPrompt);
  }
}
