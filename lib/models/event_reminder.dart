import 'package:isar/isar.dart';
import 'note.dart';

part 'event_reminder.g.dart';

@Collection()
class EventReminder {
  Id id = Isar.autoIncrement;

  late String uuid;
  late String eventName;
  String? location;

  // Parsed event date/time
  late DateTime eventDateTime;

  // Original natural language string from AI
  String? naturalDateString;

  // Flutter local notifications IDs scheduled for this event
  List<int> notificationIds = [];

  bool isCompleted = false;

  late DateTime createdAt;

  // Source note that generated this event
  final note = IsarLink<Note>();
}
