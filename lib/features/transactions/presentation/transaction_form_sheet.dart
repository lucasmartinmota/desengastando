import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/cents_input_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/budgets/data/budgets_providers.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/categories/data/categories_providers.dart';
import 'package:desengastando/features/categories/presentation/category_form_sheet.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/recurrences/data/recurrences_providers.dart';
import 'package:desengastando/features/transactions/data/transactions_providers.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:desengastando/features/transactions/presentation/delete_with_undo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formulário de lançamento em bottom sheet: criar (sem [initial]) ou editar.
///
/// Pensado para registro rápido: o valor já abre focado, "Hoje" vem
/// selecionado e só valor + categoria são obrigatórios.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({this.initial, super.key});

  final TransactionWithCategory? initial;

  static Future<void> show(
    BuildContext context, {
    TransactionWithCategory? initial,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Cobre a barra de abas (o navigator da aba fica abaixo dela).
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TransactionFormSheet(initial: initial),
  );

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late TransactionType _type;
  late final TextEditingController _amount;
  late final TextEditingController _description;
  int? _categoryId;
  late DateTime _date;
  PaymentMethod? _paymentMethod;
  bool _repeatMonthly = false;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;
  int get _cents => CentsInputFormatter.parse(_amount.text);
  bool get _canSave => _cents > 0 && _categoryId != null && !_saving;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.category.type ?? TransactionType.expense;
    _amount = TextEditingController(
      text: CentsInputFormatter.format(initial?.transaction.amountCents ?? 0),
    )..addListener(() => setState(() {}));
    _description = TextEditingController(
      text: initial?.transaction.description ?? '',
    );
    _categoryId = initial?.category.id;
    _date = (initial?.transaction.date ?? DateTime.now()).dateOnly;
    _paymentMethod = initial?.transaction.paymentMethod;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Inclui a categoria original ao editar, mesmo que tenha sido arquivada.
  List<TransactionCategory> _withInitial(List<TransactionCategory> active) {
    final category = widget.initial?.category;
    if (category == null ||
        category.type != _type ||
        active.any((c) => c.id == category.id)) {
      return active;
    }
    return [category, ...active];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final dao = ref.read(transactionsDaoProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final onSnackBar = Theme.of(context).colorScheme.onInverseSurface;
    final text = _description.text.trim();
    final description = Value(text.isEmpty ? null : text);

    // Orçamento antes e depois do lançamento: só avisa se ele subiu de faixa.
    final budgets = ref.read(budgetsDaoProvider);
    final categoryId = _categoryId!;
    final month = YearMonth.fromDate(_date);
    final isExpense = _type == TransactionType.expense;

    try {
      final before = isExpense
          ? await budgets.getProgress(categoryId, month)
          : null;
      final initial = widget.initial;
      if (initial == null) {
        final entry = TransactionsCompanion.insert(
          amountCents: _cents,
          date: _date,
          categoryId: categoryId,
          description: description,
          paymentMethod: Value(_paymentMethod),
        );
        if (_repeatMonthly) {
          await ref.read(recurrencesDaoProvider).addRepeating(entry);
        } else {
          await dao.addTransaction(entry);
        }
      } else {
        await dao.updateTransaction(
          initial.transaction.copyWith(
            amountCents: _cents,
            date: _date,
            categoryId: categoryId,
            description: description,
            paymentMethod: Value(_paymentMethod),
          ),
        );
      }
      final alert = before == null
          ? null
          : budgetAlert(
              before: before,
              after: await budgets.getProgress(categoryId, month),
            );
      navigator.pop();
      if (alert != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: onSnackBar),
                const SizedBox(width: 12),
                Expanded(child: Text(alert)),
              ],
            ),
          ),
        );
      }
    } on Exception {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o lançamento')),
      );
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    await deleteTransactionWithUndo(
      messenger: ScaffoldMessenger.of(context),
      dao: ref.read(transactionsDaoProvider),
      transaction: widget.initial!.transaction,
    );
    navigator.pop();
  }

  /// Cria uma categoria sem sair do lançamento e já a deixa selecionada.
  Future<void> _createCategory() async {
    final id = await CategoryFormSheet.show(context, type: _type);
    if (id != null && mounted) setState(() => _categoryId = id);
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked.dateOnly);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStyle = AppTheme.money(theme.textTheme.headlineMedium).copyWith(
      fontWeight: FontWeight.w800,
      color: _type == TransactionType.expense
          ? context.finance.expense
          : context.finance.income,
    );
    final categories = ref.watch(activeCategoriesProvider(_type));

    // Campos rolam; o botão fica fixo no rodapé, sempre alcançável mesmo
    // com o teclado aberto (registro rápido sem precisar rolar).
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
                          _isEditing ? 'Editar lançamento' : 'Novo lançamento',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          tooltip: 'Excluir',
                          color: context.finance.expense,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: _delete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType>(
                    segments: [
                      for (final type in TransactionType.values)
                        ButtonSegment(value: type, label: Text(type.label)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) => setState(() {
                      _type = selection.first;
                      _categoryId = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('amountField'),
                    controller: _amount,
                    autofocus: !_isEditing,
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
                  const _SectionLabel('Categoria'),
                  categories.when(
                    data: (items) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in _withInitial(items))
                          ChoiceChip(
                            showCheckmark: false,
                            avatar: Icon(
                              CategoryIcons.of(category.iconKey),
                              color: Color(category.color),
                              size: 18,
                            ),
                            label: Text(category.name),
                            selected: category.id == _categoryId,
                            onSelected: (_) =>
                                setState(() => _categoryId = category.id),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nova'),
                          tooltip: 'Nova categoria',
                          onPressed: _createCategory,
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) =>
                        Text('Erro ao carregar categorias: $error'),
                  ),
                  const _SectionLabel('Data'),
                  _DateChips(
                    date: _date,
                    onSelected: (date) => setState(() => _date = date),
                    onPickOther: _pickDate,
                  ),
                  if (!_isEditing)
                    SwitchListTile(
                      key: const Key('repeatMonthlySwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.event_repeat_rounded),
                      value: _repeatMonthly,
                      onChanged: (value) =>
                          setState(() => _repeatMonthly = value),
                      title: const Text('Repetir todo mês'),
                      subtitle: Text(
                        _repeatMonthly
                            ? 'Lançado sozinho todo dia ${_date.day}'
                            : 'Para salário, aluguel, assinaturas...',
                      ),
                    )
                  else if (widget.initial!.transaction.recurrenceId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_repeat_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lançamento fixo: mudanças aqui valem só para '
                              'este mês.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const _SectionLabel('Forma de pagamento (opcional)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final method in PaymentMethod.values)
                        ChoiceChip(
                          label: Text(method.label),
                          selected: _paymentMethod == method,
                          onSelected: (selected) => setState(
                            () => _paymentMethod = selected ? method : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _description,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      counterText: '',
                    ),
                  ),
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
              child: Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DateChips extends StatelessWidget {
  const _DateChips({
    required this.date,
    required this.onSelected,
    required this.onPickOther,
  });

  final DateTime date;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onPickOther;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().dateOnly;
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final isOther = date != today && date != yesterday;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Hoje'),
          selected: date == today,
          onSelected: (_) => onSelected(today),
        ),
        ChoiceChip(
          label: const Text('Ontem'),
          selected: date == yesterday,
          onSelected: (_) => onSelected(yesterday),
        ),
        ChoiceChip(
          showCheckmark: false,
          avatar: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(isOther ? DateLabels.day(date) : 'Outra data'),
          selected: isOther,
          onSelected: (_) => onPickOther(),
        ),
      ],
    );
  }
}
