import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'gemini_service.dart';
import 'database_service.dart';
import 'embedding_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'native_bridge_service.dart';

// ─── Secure storage ────────────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final geminiApiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: AppConstants.geminiApiKeyStorageKey);
});

// ─── Gemini service ────────────────────────────────────────────────────────

final geminiServiceProvider = Provider<GeminiService?>((ref) {
  final asyncKey = ref.watch(geminiApiKeyProvider);
  return asyncKey.when(
    data: (key) => key != null && key.isNotEmpty ? GeminiService(key) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── Database ─────────────────────────────────────────────────────────────

final databaseServiceProvider = Provider<DatabaseService>(
  (_) => DatabaseService.instance,
);

// ─── Embedding service ────────────────────────────────────────────────────

final embeddingServiceProvider = Provider<EmbeddingService?>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  if (gemini == null) return null;
  return EmbeddingService(gemini);
});

// ─── Other services ────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);

final nativeBridgeProvider = Provider<NativeBridgeService>(
  (_) => NativeBridgeService.instance,
);
