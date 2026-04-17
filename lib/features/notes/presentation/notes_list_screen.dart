import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../providers/notes_providers.dart';
import 'widgets/note_card.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = ref.watch(searchQueryProvider);
    final notesAsync = query.isEmpty
        ? ref.watch(notesStreamProvider)
        : ref.watch(searchResultsProvider).when(
              data: (notes) => AsyncValue.data(notes),
              loading: () => const AsyncValue.loading(),
              error: (e, s) => AsyncValue.error(e, s),
            );

    return GradientScaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              )
            : const Text('Notes', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notes_rounded,
              title: query.isEmpty ? 'No notes yet' : 'No results',
              subtitle: query.isEmpty
                  ? 'Tap the mic or pen to create your first note'
                  : 'Try a different search term',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: notes.length,
            itemBuilder: (context, i) => NoteCard(
              note: notes[i],
              animationIndex: i,
              onTap: () => context.push('/notes/${notes[i].id}'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
    );
  }
}
