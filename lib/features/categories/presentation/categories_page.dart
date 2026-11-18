import 'dart:async';

import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/categories/data/categories_providers.dart';
import 'package:desengastando/features/categories/presentation/category_form_sheet.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gerenciamento de categorias: uma aba por tipo, com reordenação por
/// arraste e as arquivadas no fim.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: TransactionType.values.length,
    vsync: this,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            for (final type in TransactionType.values)
              Tab(
                text: type == TransactionType.expense ? 'Despesas' : 'Receitas',
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Sem Hero: as abas ficam montadas no IndexedStack e os FABs
        // conflitariam ao abrir uma tela por cima.
        heroTag: null,
        onPressed: () => CategoryFormSheet.show(
          context,
          type: TransactionType.values[_tabs.index],
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova categoria'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final type in TransactionType.values) _CategoryList(type: type),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerStatefulWidget {
  const _CategoryList({required this.type});

  final TransactionType type;

  @override
  ConsumerState<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<_CategoryList> {
  /// Ordem otimista enquanto o banco não emite a nova lista: o
  /// `ReorderableListView` precisa refletir o arraste no mesmo frame.
  List<TransactionCategory>? _pending;

  void _onReorder(List<TransactionCategory> active, int from, int to) {
    final list = [...active];
    final item = list.removeAt(from);
    list.insert(to, item);
    setState(() => _pending = list);
    unawaited(
      ref.read(categoriesDaoProvider).reorder([for (final c in list) c.id]),
    );
  }

  void _edit(TransactionCategory category) =>
      CategoryFormSheet.show(context, initial: category);

  @override
  Widget build(BuildContext context) {
    ref.listen(allCategoriesProvider(widget.type), (_, _) {
      if (_pending != null) setState(() => _pending = null);
    });
    final categories = ref.watch(allCategoriesProvider(widget.type));

    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Erro ao carregar categorias: $error')),
      data: (all) {
        final active =
            _pending ??
            [
              for (final c in all)
                if (!c.archived) c,
            ];
        final archived = [
          for (final c in all)
            if (c.archived) c,
        ];
        final theme = Theme.of(context);
        final hintStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

        return ReorderableListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          buildDefaultDragHandles: false,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Toque para editar. Arraste pela alça para mudar a ordem '
              'em que aparecem no lançamento.',
              style: hintStyle,
            ),
          ),
          itemCount: active.length,
          onReorderItem: (from, to) => _onReorder(active, from, to),
          itemBuilder: (context, index) {
            final category = active[index];
            return ListTile(
              key: ValueKey(category.id),
              leading: CategoryAvatar(category: category),
              title: Text(category.name),
              onTap: () => _edit(category),
              trailing: ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Arrastar ${category.name}',
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ),
            );
          },
          footer: archived.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                      child: Text(
                        'Arquivadas',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Não aparecem em novos lançamentos, mas continuam '
                        'nos antigos.',
                        style: hintStyle,
                      ),
                    ),
                    for (final category in archived)
                      Opacity(
                        opacity: 0.6,
                        child: ListTile(
                          leading: CategoryAvatar(category: category),
                          title: Text(category.name),
                          trailing: const Icon(Icons.archive_outlined),
                          onTap: () => _edit(category),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
