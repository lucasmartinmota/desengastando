import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/core/formatters/cents_input_formatter.dart';
import 'package:desengastando/core/formatters/date_labels.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/categories/data/categories_providers.dart';
import 'package:desengastando/features/categories/presentation/category_icons.dart';
import 'package:desengastando/features/recurrences/data/recurrences_providers.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_schedule.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_with_category.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cria ou edita um lançamento fixo mensal (conta ou receita).
class RecurrenceFormSheet extends ConsumerStatefulWidget {
  const RecurrenceFormSheet({
    this.initial,
    this.type = TransactionType.expense,
    super.key,
  });

  final RecurrenceWithCategory? initial;

  /// Tipo sugerido ao criar.
  final TransactionType type;

  static Future<void> show(
    BuildContext context, {
    RecurrenceWithCategory? initial,
    TransactionType type = TransactionType.expense,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => RecurrenceFormSheet(initial: initial, type: type),
  );

  @override
  ConsumerState<RecurrenceFormSheet> createState() =>
      _RecurrenceFormSheetState();
}

class _RecurrenceFormSheetState extends ConsumerState<RecurrenceFormSheet> {
  late TransactionType _type;
  late final TextEditingController _amount;
  late final TextEditingController _description;
  int? _categoryId;
  late int _day;
  PaymentMethod? _paymentMethod;
  bool _includeCurrentMonth = true;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;
  int get _cents => CentsInputFormatter.parse(_amount.text);
  bool get _canSave => _cents > 0 && _categoryId != null && !_saving;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final recurrence = initial?.recurrence;
    _type = initial?.category.type ?? widget.type;
    _amount = TextEditingController(
      text: CentsInputFormatter.format(recurrence?.amountCents ?? 0),
    )..addListener(() => setState(() {}));
    _description = TextEditingController(text: recurrence?.description ?? '');
    _categoryId = initial?.category.id;
    _day = recurrence?.dayOfMonth ?? DateTime.now().day;
    _paymentMethod = recurrence?.paymentMethod;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  /// O lançamento deste mês já deveria ter saído (o dia já chegou)?
  bool get _currentMonthDue {
    final today = DateTime.now();
    return !RecurrenceSchedule.dueDate(
      YearMonth.fromDate(today),
      _day,
    ).isAfter(today.dateOnly);
  }

  /// Ao editar, mantém a categoria original mesmo que tenha sido arquivada.
  List<TransactionCategory> _withInitial(List<TransactionCategory> active) {
    final category = widget.initial?.category;
    if (category == null || active.any((c) => c.id == category.id)) {
      return active;
    }
    return [category, ...active];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final dao = ref.read(recurrencesDaoProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = _description.text.trim();
    final description = text.isEmpty ? null : text;

    try {
      final initial = widget.initial;
      if (initial == null) {
        await dao.createRecurrence(
          amountCents: _cents,
          categoryId: _categoryId!,
          dayOfMonth: _day,
          includeCurrentMonth: _includeCurrentMonth,
          description: description,
          paymentMethod: _paymentMethod,
        );
      } else {
        await dao.updateRecurrence(
          initial.recurrence.copyWith(
            amountCents: _cents,
            categoryId: _categoryId,
            dayOfMonth: _day,
            description: Value(description),
            paymentMethod: Value(_paymentMethod),
          ),
        );
      }
      navigator.pop();
    } on Exception {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar')),
      );
    }
  }

  Future<void> _togglePaused() async {
    final recurrence = widget.initial!.recurrence;
    final navigator = Navigator.of(context);
    await ref
        .read(recurrencesDaoProvider)
        .setActive(recurrence.id, active: !recurrence.active);
    navigator.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento fixo?'),
        content: const Text(
          'Ele para de ser lançado nos próximos meses. Os lançamentos já '
          'feitos continuam na sua lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await ref
        .read(recurrencesDaoProvider)
        .deleteRecurrence(widget.initial!.recurrence.id);
    navigator.pop();
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
    final recurrence = widget.initial?.recurrence;
    final paused = recurrence != null && !recurrence.active;
    final currentMonthName = DateLabels.monthName(YearMonth.now());

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
                              ? 'Editar lançamento fixo'
                              : 'Novo lançamento fixo',
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
                  const SizedBox(height: 4),
                  Text(
                    _isEditing
                        ? 'Mudanças valem a partir do próximo lançamento; os '
                              'que já saíram não mudam.'
                        : 'Lançado sozinho todo mês, no dia escolhido.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing)
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
                    key: const Key('recurrenceAmountField'),
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
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) =>
                        Text('Erro ao carregar categorias: $error'),
                  ),
                  const _SectionLabel('Todo mês, no dia'),
                  DropdownButtonFormField<int>(
                    key: const Key('recurrenceDayField'),
                    initialValue: _day,
                    decoration: const InputDecoration(
                      helperText:
                          'Em meses sem esse dia, vale o último dia do mês.',
                    ),
                    items: [
                      for (var day = 1; day <= 31; day++)
                        DropdownMenuItem(value: day, child: Text('Dia $day')),
                    ],
                    onChanged: (day) => setState(() => _day = day ?? _day),
                  ),
                  if (!_isEditing && _currentMonthDue)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeCurrentMonth,
                      onChanged: (value) =>
                          setState(() => _includeCurrentMonth = value),
                      title: Text('Lançar também o de $currentMonthName'),
                      subtitle: const Text(
                        'O dia deste mês já chegou. Desligue se você já '
                        'lançou à mão.',
                      ),
                    ),
                  if (_isEditing)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: !paused,
                      onChanged: (_) => _togglePaused(),
                      title: const Text('Ativo'),
                      subtitle: Text(
                        paused
                            ? 'Pausado: nada é lançado até reativar.'
                            : 'Próximo: '
                                  '${DateLabels.day(widget.initial!.nextDate)}',
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
                      labelText: 'Descrição (ex.: Salário, Aluguel)',
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
              child: Text(_isEditing ? 'Salvar alterações' : 'Criar'),
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
