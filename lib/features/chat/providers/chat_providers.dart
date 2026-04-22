import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../models/ai_result.dart';
import '../domain/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  if (gemini == null) return null;
  return ChatRepository(
    geminiService: gemini,
    databaseService: ref.watch(databaseServiceProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

// ─── Messages list ────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addUserMessage(String content) {
    state = [
      ...state,
      ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void addAiMessage(String content, {bool isStreaming = false}) {
    state = [
      ...state,
      ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: isStreaming,
      ),
    ];
  }

  void appendToLastAiMessage(String chunk) {
    if (state.isEmpty || state.last.isUser) return;
    final last = state.last;
    state = [
      ...state.sublist(0, state.length - 1),
      last.copyWith(content: last.content + chunk, isStreaming: true),
    ];
  }

  void finalizeLastAiMessage() {
    if (state.isEmpty || state.last.isUser) return;
    final last = state.last;
    state = [
      ...state.sublist(0, state.length - 1),
      last.copyWith(isStreaming: false),
    ];
  }

  void clear() => state = [];
}

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((_) => ChatNotifier());

final chatLoadingProvider = StateProvider<bool>((_) => false);
