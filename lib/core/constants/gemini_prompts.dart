class GeminiPrompts {
  GeminiPrompts._();

  static const String transcription = '''
Transcribe this audio recording faithfully and accurately.
Return only the transcribed text with no additional commentary or formatting.
Preserve natural speech patterns, pauses indicated by "..." where appropriate.
''';

  static const String voiceNoteAnalysis = '''
You are a smart note-taking assistant. Analyze the following voice transcript and extract structured information.

Return a JSON object with exactly this structure:
{
  "title": "A concise title for this note (max 8 words)",
  "summary": "A 2-3 sentence summary of the main content",
  "category": "One of: Personal, Work, Ideas, Events, Shopping, Health, Finance, Passwords, Articles, Contacts, Code, Other",
  "reminders": [
    {
      "task": "What to be reminded about",
      "datetime_natural": "Natural language date/time like 'tomorrow at 3pm' or 'next Monday'"
    }
  ],
  "events": [
    {
      "event_name": "Name of the event",
      "event_datetime_natural": "Natural language date/time",
      "location": "Location if mentioned, null otherwise"
    }
  ]
}

The reminders array should only contain explicit reminder requests like "remind me to...", "don't forget to...", "I need to remember...".
The events array should contain meetings, appointments, deadlines, or scheduled activities.

Transcript:
''';

  static const String screenshotAnalysis = '''
Analyze this screenshot image carefully. Extract all useful information.

Return a JSON object with exactly this structure:
{
  "title": "A concise title describing what this screenshot shows (max 8 words)",
  "summary": "A 2-3 sentence summary of the key information in this screenshot",
  "category": "One of: Events, Info, Passwords, Receipt, Article, Code, Contact, Shopping, Other",
  "ocr_text": "The complete text extracted from the image, preserving structure",
  "events": [
    {
      "event_name": "Name of the event or appointment",
      "event_datetime_natural": "Date and time as shown in the image",
      "location": "Location if visible, null otherwise"
    }
  ],
  "key_info": [
    "Important piece of information 1",
    "Important piece of information 2"
  ]
}

Events should include any dates, times, appointments, deadlines, or scheduled activities visible in the screenshot.
For password screenshots: extract the service name but do NOT extract the actual password in key_info.
''';

  static const String textNoteAnalysis = '''
You are a smart note-taking assistant. Analyze this text note and extract structured information.

Return a JSON object with exactly this structure:
{
  "title": "A concise title for this note (max 8 words, if no title is evident from content)",
  "summary": "A 2-3 sentence summary",
  "category": "One of: Personal, Work, Ideas, Events, Shopping, Health, Finance, Passwords, Articles, Contacts, Code, Other",
  "reminders": [
    {
      "task": "What to be reminded about",
      "datetime_natural": "Natural language date/time"
    }
  ],
  "events": [
    {
      "event_name": "Name of the event",
      "event_datetime_natural": "Natural language date/time",
      "location": "Location if mentioned, null otherwise"
    }
  ]
}

Note content:
''';

  static String chatSystemPrompt(String notesContext) => '''
You are Myspace AI, a personal assistant with access to the user's notes, memories, and saved information.

Here is the user's saved data:

$notesContext

---

Answer questions accurately based on this context. Be conversational and helpful.
If the context contains the information, cite it specifically.
If you cannot find relevant information in the context, say so honestly.
Format your responses with markdown when helpful (bullet points, bold text, etc.).
Keep responses concise but complete.
''';

  static const String parseDateTime = '''
Convert this natural language date/time expression to an ISO 8601 datetime string.
Today's date context will be provided. Return ONLY the ISO 8601 string (e.g., "2025-12-25T15:00:00") or "unknown" if not parseable.
Do not include any other text.

Expression:
''';

  static const String smartNotificationTiming = '''
Given an event name and its date/time, determine the best notification strategy.
Return a JSON array of objects with "offset_hours" (how many hours before the event to notify) and "message" (notification body text).

Example output: [{"offset_hours": 24, "message": "Your dentist appointment is tomorrow"}, {"offset_hours": 2, "message": "Dentist appointment in 2 hours"}]

Be smart about timing:
- For important events: notify 1 week, 1 day, and 2 hours before
- For casual events: notify 1 day and 2 hours before
- For same-day events: notify 2 hours and 30 minutes before
- Always include a "right before" notification

Event:
''';
}
