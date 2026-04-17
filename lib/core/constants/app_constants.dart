class AppConstants {
  AppConstants._();

  static const String appName = 'Myspace AI';
  static const String appTagline = 'Your personal memory';

  // ─── Gemini models ────────────────────────────────────────────────────────
  static const String geminiFlash = 'gemini-2.0-flash';
  static const String geminiPro = 'gemini-1.5-pro';
  static const String geminiEmbedding = 'text-embedding-004';

  // ─── Files API ────────────────────────────────────────────────────────────
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com';
  static const String filesApiPath = '/upload/v1beta/files';

  // ─── Limits ───────────────────────────────────────────────────────────────
  static const int maxInlineFileSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int maxInlineImageSizeBytes = 4 * 1024 * 1024;  // 4 MB
  static const int maxNotesInChatContext = 50;
  static const int embeddingVectorSize = 768;
  static const int maxRecordingMinutes = 5;
  static const int chatTopKNotes = 15;

  // ─── Notification channels ────────────────────────────────────────────────
  static const String notificationChannelId = 'myspace_reminders';
  static const String notificationChannelName = 'Myspace AI Reminders';
  static const String foregroundChannelId = 'myspace_foreground';
  static const String foregroundChannelName = 'Myspace AI Service';

  // ─── Storage keys ─────────────────────────────────────────────────────────
  static const String geminiApiKeyStorageKey = 'gemini_api_key';
  static const String firstLaunchKey = 'first_launch_done';
  static const String floatingButtonEnabledKey = 'floating_button_enabled';

  // ─── AI categories ────────────────────────────────────────────────────────
  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Ideas',
    'Events',
    'Shopping',
    'Health',
    'Finance',
    'Passwords',
    'Articles',
    'Contacts',
    'Code',
    'Other',
  ];
}
