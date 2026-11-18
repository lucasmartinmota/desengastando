import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/categories/data/categories_providers.dart';
import 'package:desengastando/features/categories/domain/category_name.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formulário de categoria em bottom sheet: criar (sem [initial]) ou editar.
///
/// Ao criar, devolve o id da nova categoria (útil para já selecioná-la no
/// formulário de lançamento).
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    this.initial,
    this.type = TransactionType.expense,
    super.key,
  });

  final TransactionCategory? initial;

  /// Tipo sugerido ao criar. Ao editar, vale o tipo de [initial].
  final TransactionType type;

  static Future<int?> show(
    BuildContext context, {
    TransactionCategory? initial,
    TransactionType type = TransactionType.expense,
  }) => showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => CategoryFormSheet(initial: initial, type: type),
  );

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late TransactionType _type;
  late final TextEditingController _name;
  late String _iconKey;
  late int _color;
  bool _touched = false;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? widget.type;
    _name = TextEditingController(text: initial?.name ?? '')
      ..addListener(() => setState(() => _touched = true));
    _iconKey = initial?.iconKey ?? CategoryIcons.all.keys.first;
    _color = initial?.color ?? CategoryColors.palette.first.$1;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final dao = ref.read(categoriesDaoProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();

    try {
      final initial = widget.initial;
      if (initial == null) {
        final id = await dao.createCategory(
          name: name,
          iconKey: _iconKey,
          color: _color,
          type: _type,
        );
        navigator.pop(id);
      } else {
        await dao.updateCategory(
          initial.copyWith(name: name, iconKey: _iconKey, color: _color),
        );
        navigator.pop(initial.id);
      }
    } on Exception {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a categoria')),
      );
    }
  }

  Future<void> _toggleArchived() async {
    final category = widget.initial!;
    final archive = !category.archived;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dao = ref.read(categoriesDaoProvider);
    await dao.setArchived(category.id, archived: archive);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        // Com ação o SnackBar persistiria por padrão; aqui ele expira.
        persist: false,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => dao.setArchived(category.id, archived: !archive),
        ),
        content: Text(
          archive
              ? '"${category.name}" arquivada. Os lançamentos antigos '
                    'continuam com ela.'
              : '"${category.name}" voltou para a lista',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing =
        ref.watch(allCategoriesProvider(_type)).value ??
        const <TransactionCategory>[];
    final error = validateCategoryName(
      _name.text,
      existing,
      exceptId: widget.initial?.id,
    );
    final canSave = error == null && !_saving;
    final archived = widget.initial?.archived ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing ? 'Editar categoria' : 'Nova categoria',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        TextButton.icon(
                          onPressed: _toggleArchived,
                          icon: Icon(
                            archived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                          label: Text(archived ? 'Reativar' : 'Arquivar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    Text(
                      'Categoria de ${_type.label.toLowerCase()}. O tipo não '
                      'muda para não alterar lançamentos já feitos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    SegmentedButton<TransactionType>(
                      segments: [
                        for (final type in TransactionType.values)
                          ButtonSegment(value: type, label: Text(type.label)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selection) =>
                          setState(() => _type = selection.first),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Preview(iconKey: _iconKey, color: Color(_color)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('categoryNameField'),
                          controller: _name,
                          autofocus: !_isEditing,
                          maxLength: 40,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Nome',
                            counterText: '',
                            // Só reclama depois que a pessoa começou a digitar.
                            errorText: _touched ? error : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const _SectionLabel('Cor'),
                  _EvenGrid(
                    maxExtent: 52,
                    children: [
                      for (final (value, name) in CategoryColors.palette)
                        _ColorDot(
                          color: Color(value),
                          name: name,
                          selected: value == _color,
                          onTap: () => setState(() => _color = value),
                        ),
                    ],
                  ),
                  const _SectionLabel('Ícone'),
                  _EvenGrid(
                    maxExtent: 60,
                    children: [
                      for (final MapEntry(:key, value: icon)
                          in CategoryIcons.all.entries)
                        _IconOption(
                          icon: icon,
                          color: Color(_color),
                          selected: key == _iconKey,
                          onTap: () => setState(() => _iconKey = key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isEditing ? 'Salvar alterações' : 'Criar categoria'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.iconKey, required this.color});

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 28,
        backgroundColor: color.withValues(alpha: 0.16),
        child: Icon(CategoryIcons.of(iconKey), color: color, size: 28),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: name,
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ring : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? color : Colors.transparent, width: 2),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.16)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Icon(
            icon,
            color: selected ? color : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Grade quadrada que ocupa a largura toda, com colunas de até [maxExtent].
class _EvenGrid extends StatelessWidget {
  const _EvenGrid({required this.maxExtent, required this.children});

  final double maxExtent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: maxExtent,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
