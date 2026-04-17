class AiEvent {
  final String eventName;
  final String eventDatetimeNatural;
  final String? location;

  const AiEvent({
    required this.eventName,
    required this.eventDatetimeNatural,
    this.location,
  });

  factory AiEvent.fromJson(Map<String, dynamic> json) => AiEvent(
        eventName: json['event_name'] as String? ?? json['eventName'] as String? ?? '',
        eventDatetimeNatural: json['event_datetime_natural'] as String? ??
            json['eventDatetimeNatural'] as String? ??
            '',
        location: json['location'] as String?,
      );

  AiEvent copyWith({String? eventName, String? eventDatetimeNatural, String? location}) =>
      AiEvent(
        eventName: eventName ?? this.eventName,
        eventDatetimeNatural: eventDatetimeNatural ?? this.eventDatetimeNatural,
        location: location ?? this.location,
      );
}

class AiReminder {
  final String task;
  final String datetimeNatural;

  const AiReminder({required this.task, required this.datetimeNatural});

  factory AiReminder.fromJson(Map<String, dynamic> json) => AiReminder(
        task: json['task'] as String? ?? '',
        datetimeNatural: json['datetime_natural'] as String? ??
            json['datetimeNatural'] as String? ??
            '',
      );

  AiReminder copyWith({String? task, String? datetimeNatural}) => AiReminder(
        task: task ?? this.task,
        datetimeNatural: datetimeNatural ?? this.datetimeNatural,
      );
}

class AiNoteResult {
  final String title;
  final String summary;
  final String category;
  final String? rawTranscript;
  final String? ocrText;
  final String? contentType;
  final List<AiEvent> events;
  final List<AiReminder> reminders;
  final List<String> keyInfo;

  const AiNoteResult({
    required this.title,
    required this.summary,
    this.category = 'Other',
    this.rawTranscript,
    this.ocrText,
    this.contentType,
    this.events = const [],
    this.reminders = const [],
    this.keyInfo = const [],
  });

  factory AiNoteResult.fromJson(Map<String, dynamic> json) {
    List<AiEvent> parseEvents(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => AiEvent.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<AiReminder> parseReminders(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => AiReminder.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<String> parseKeyInfo(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => e.toString()).toList();
    }

    return AiNoteResult(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      rawTranscript: json['rawTranscript'] as String?,
      ocrText: json['ocr_text'] as String? ?? json['ocrText'] as String?,
      contentType: json['contentType'] as String?,
      events: parseEvents(json['events']),
      reminders: parseReminders(json['reminders']),
      keyInfo: parseKeyInfo(json['key_info'] ?? json['keyInfo']),
    );
  }

  AiNoteResult copyWith({
    String? title,
    String? summary,
    String? category,
    String? rawTranscript,
    String? ocrText,
    String? contentType,
    List<AiEvent>? events,
    List<AiReminder>? reminders,
    List<String>? keyInfo,
  }) =>
      AiNoteResult(
        title: title ?? this.title,
        summary: summary ?? this.summary,
        category: category ?? this.category,
        rawTranscript: rawTranscript ?? this.rawTranscript,
        ocrText: ocrText ?? this.ocrText,
        contentType: contentType ?? this.contentType,
        events: events ?? this.events,
        reminders: reminders ?? this.reminders,
        keyInfo: keyInfo ?? this.keyInfo,
      );
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) =>
      ChatMessage(
        content: content ?? this.content,
        isUser: isUser ?? this.isUser,
        timestamp: timestamp ?? this.timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}
