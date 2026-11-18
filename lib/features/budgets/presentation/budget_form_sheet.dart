import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/formatters/cents_input_formatter.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/budgets/data/budgets_providers.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/categories/data/categories_providers.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Define o limite mensal de uma categoria de despesa: criar (sem
/// [initial], escolhendo a categoria) ou editar/remover.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({this.initial, super.key});

  final BudgetProgress? initial;

  static Future<void> show(BuildContext context, {BudgetProgress? initial}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => BudgetFormSheet(initial: initial),
      );

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amount;
  int? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;
  int get _cents => CentsInputFormatter.parse(_amount.text);
  bool get _canSave => _cents > 0 && _categoryId != null && !_saving;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: CentsInputFormatter.format(widget.initial?.limitCents ?? 0),
    )..addListener(() => setState(() {}));
    _categoryId = widget.initial?.category.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(budgetsDaoProvider)
          .setBudget(categoryId: _categoryId!, limitCents: _cents);
      navigator.pop();
    } on Exception {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o orçamento')),
      );
    }
  }

  Future<void> _remove() async {
    final initial = widget.initial!;
    final dao = ref.read(budgetsDaoProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await dao.removeBudget(initial.category.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        persist: false,
        content: Text('Orçamento de ${initial.category.name} removido'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => dao.setBudget(
            categoryId: initial.category.id,
            limitCents: initial.limitCents,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStyle = AppTheme.money(
      theme.textTheme.headlineMedium,
    ).copyWith(fontWeight: FontWeight.w800);
    final initial = widget.initial;

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
                          _isEditing
                              ? 'Orçamento de ${initial!.category.name}'
                              : 'Novo orçamento',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        TextButton.icon(
                          onPressed: _remove,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remover'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limite mensal: vale para todos os meses, e você é '
                    'avisado ao chegar em '
                    '${(BudgetProgress.warningRatio * 100).round()}%.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('budgetAmountField'),
                    controller: _amount,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CentsInputFormatter()],
                    style: amountStyle,
                    decoration: InputDecoration(
                      prefixText: r'R$ ',
                      prefixStyle: amountStyle,
                      hintText: '0,00',
                      hintStyle: amountStyle.copyWith(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Categoria',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CategoryPicker(
                      selectedId: _categoryId,
                      onSelected: (id) => setState(() => _categoryId = id),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isEditing ? 'Salvar alterações' : 'Definir limite'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Categorias de despesa ativas que ainda não têm orçamento.
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({required this.selectedId, required this.onSelected});

  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgeted = {
      for (final b
          in ref.watch(budgetProgressProvider).value ??
              const <BudgetProgress>[])
        b.category.id,
    };
    final categories =
        ref.watch(activeCategoriesProvider(TransactionType.expense)).value ??
        const <TransactionCategory>[];
    final available = [
      for (final c in categories)
        if (!budgeted.contains(c.id)) c,
    ];

    if (available.isEmpty) {
      return Text(
        'Todas as categorias de despesa já têm orçamento.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in available)
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              CategoryIcons.of(category.iconKey),
              color: Color(category.color),
              size: 18,
            ),
            label: Text(category.name),
            selected: category.id == selectedId,
            onSelected: (_) => onSelected(category.id),
          ),
      ],
    );
  }
}
