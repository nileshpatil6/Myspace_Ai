import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category.dart';
import '../../../models/note.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../../notes/presentation/widgets/note_card.dart';

final _allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllCategories();
});

final _selectedCategoryProvider = StateProvider<Category?>((ref) => null);

final _categoryNotesProvider =
    FutureProvider.autoDispose.family<List<Note>, int>((ref, catId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getNotesByCategory(catId);
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catsAsync = ref.watch(_allCategoriesProvider);
    final selectedCat = ref.watch(_selectedCategoryProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Categories',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Category chips row
          SizedBox(
            height: 48,
            child: catsAsync.when(
              data: (cats) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  final isSelected = selectedCat?.id == cat.id;
                  var chipColor = AppColors.categoryColors[cat.name] ?? AppColors.orange;

                  return GestureDetector(
                    onTap: () {
                      ref.read(_selectedCategoryProvider.notifier).state =
                          isSelected ? null : cat;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor : chipColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? chipColor : chipColor.withAlpha(60),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : chipColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 8),

          // Notes for selected category
          Expanded(
            child: selectedCat == null
                ? _AllCategoriesGrid(
                    catsAsync: catsAsync,
                    isDark: isDark,
                    onCategoryTap: (cat) {
                      ref.read(_selectedCategoryProvider.notifier).state = cat;
                    },
                  )
                : _CategoryNotesList(categoryId: selectedCat.id),
          ),
        ],
      ),
    );
  }
}

class _AllCategoriesGrid extends StatelessWidget {
  const _AllCategoriesGrid({
    required this.catsAsync,
    required this.isDark,
    required this.onCategoryTap,
  });
  final AsyncValue<List<Category>> catsAsync;
  final bool isDark;
  final void Function(Category) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return catsAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.folder_open_rounded,
            title: 'No categories yet',
            subtitle: 'Categories are created automatically as you add notes',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: cats.length,
          itemBuilder: (_, i) => _CategoryCard(
            category: cats[i],
            isDark: isDark,
            index: i,
            onTap: () => onCategoryTap(cats[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.index,
    required this.onTap,
  });
  final Category category;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteCount = ref.watch(_categoryNotesProvider(category.id));
    var chipColor = AppColors.categoryColors[category.name] ?? AppColors.orange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: chipColor.withAlpha(isDark ? 25 : 18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipColor.withAlpha(60), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              _categoryIcon(category.name),
              color: chipColor,
              size: 24,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
                noteCount.when(
                  data: (notes) => Text(
                    '${notes.length} note${notes.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: chipColor.withAlpha(180),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  IconData _categoryIcon(String name) {
    return switch (name) {
      'Personal' => Icons.person_rounded,
      'Work' => Icons.work_rounded,
      'Ideas' => Icons.lightbulb_rounded,
      'Events' => Icons.event_rounded,
      'Shopping' => Icons.shopping_bag_rounded,
      'Health' => Icons.favorite_rounded,
      'Finance' => Icons.account_balance_rounded,
      'Passwords' => Icons.lock_rounded,
      'Articles' => Icons.article_rounded,
      'Contacts' => Icons.contacts_rounded,
      'Code' => Icons.code_rounded,
      _ => Icons.folder_rounded,
    };
  }
}

class _CategoryNotesList extends ConsumerWidget {
  const _CategoryNotesList({required this.categoryId});
  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(_categoryNotesProvider(categoryId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notes_rounded,
            title: 'No notes in this category',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: notes.length,
          itemBuilder: (_, i) => NoteCard(
            note: notes[i],
            animationIndex: i,
            onTap: () => context.push('/notes/${notes[i].id}'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
