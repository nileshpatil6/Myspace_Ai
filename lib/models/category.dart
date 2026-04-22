import 'package:isar/isar.dart';
import 'note.dart';

part 'category.g.dart';

@Collection()
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String name;

  String? colorHex;

  // Whether this category was auto-created by AI
  bool isAiGenerated = false;

  // Whether the user explicitly created/customized this
  bool isUserDefined = false;

  late DateTime createdAt;

  // Back-reference to notes
  @Backlink(to: 'category')
  final notes = IsarLinks<Note>();
}
