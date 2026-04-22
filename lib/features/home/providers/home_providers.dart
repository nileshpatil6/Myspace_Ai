import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../models/event_reminder.dart';
import '../../../features/notes/providers/notes_providers.dart';

final upcomingEventsProvider = FutureProvider<List<EventReminder>>((ref) async {
  ref.watch(notesStreamProvider); // refresh when notes change
  final db = ref.watch(databaseServiceProvider);
  return db.getUpcomingEvents(limit: 5);
});

final categoriesCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notesStreamProvider);
  final db = ref.watch(databaseServiceProvider);
  final cats = await db.getAllCategories();
  return cats.length;
});
