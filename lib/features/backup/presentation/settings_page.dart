import 'package:desengastando/app/router.dart';
import 'package:desengastando/features/backup/data/backup_providers.dart';
import 'package:desengastando/features/backup/data/backup_service.dart';
import 'package:desengastando/features/recurrences/data/recurrences_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Ajustes: categorias, backup/exportação e informações do app.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _busy = false;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Retângulo do item tocado (o iPad ancora a folha de compartilhar nele).
  Rect? _originOf(BuildContext tileContext) {
    final box = tileContext.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup(BuildContext tileContext) {
    final origin = _originOf(tileContext);
    return _run(() async {
      final json = await ref.read(backupServiceProvider).exportJson();
      await ref
          .read(backupFilesProvider)
          .share(
            fileName: 'desengastando-backup-$_today.json',
            content: json,
            mimeType: 'application/json',
            origin: origin,
          );
    }, 'Não foi possível gerar o backup');
  }

  Future<void> _exportCsv(BuildContext tileContext) {
    final origin = _originOf(tileContext);
    return _run(() async {
      final csv = await ref.read(backupServiceProvider).exportCsv();
      await ref
          .read(backupFilesProvider)
          .share(
            fileName: 'desengastando-lancamentos-$_today.csv',
            content: csv,
            mimeType: 'text/csv',
            origin: origin,
          );
    }, 'Não foi possível exportar a planilha');
  }

  /// Escolher e confirmar ficam fora do [_run]: o indicador de progresso
  /// só aparece durante a gravação, não enquanto a pessoa decide.
  Future<void> _restore() async {
    if (_busy) return;
    final service = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final BackupContents contents;
    try {
      final source = await ref.read(backupFilesProvider).pickText();
      if (source == null) return;
      contents = service.parse(source);
    } on BackupFormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível ler o arquivo')),
      );
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restore_rounded),
        title: const Text('Restaurar backup?'),
        content: Text(
          'Backup de ${DateFormat('dd/MM/yyyy').format(contents.exportedAt)} '
          'com ${_count(contents.transactions.length, 'lançamento')}, '
          '${_count(contents.categories.length, 'categoria')}, '
          '${_count(contents.budgets.length, 'orçamento')} e '
          '${_count(contents.recurrences.length, 'lançamento fixo', 'lançamentos fixos')}.\n\n'
          'Todos os dados atuais serão substituídos. Se quiser guardá-los, '
          'exporte um backup antes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Substituir dados'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await service.restore(contents);
      // Fixos do backup podem ter meses vencidos desde que ele foi feito.
      await ref.read(recurrencesDaoProvider).generateDue();
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup restaurado')),
      );
    }, 'Não foi possível restaurar o backup');
  }

  static String _count(int n, String word, [String? plural]) =>
      '$n ${n == 1 ? word : plural ?? '${word}s'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Header('Organização'),
          ListTile(
            leading: const Icon(Icons.event_repeat_rounded),
            title: const Text('Lançamentos fixos'),
            subtitle: const Text('Salário, aluguel, assinaturas...'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.recurrences),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorias'),
            subtitle: const Text('Criar, editar, reordenar e arquivar'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.categories),
          ),
          const _Header('Seus dados'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _Hint(
              'Tudo fica só neste aparelho. Faça backups de vez em quando '
              'e guarde no Drive, iCloud ou onde preferir.',
            ),
          ),
          Builder(
            builder: (tileContext) => ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Exportar backup'),
              subtitle: const Text('Arquivo .json com todos os dados'),
              onTap: () => _exportBackup(tileContext),
            ),
          ),
          ListTile(
            enabled: !_busy,
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restaurar backup'),
            subtitle: const Text('Substitui os dados atuais'),
            onTap: _restore,
          ),
          Builder(
            builder: (tileContext) => ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Exportar planilha'),
              subtitle: const Text('Lançamentos em .csv (Excel, Sheets)'),
              onTap: () => _exportCsv(tileContext),
            ),
          ),
          const _Header('Sobre'),
          const AboutListTile(
            icon: Icon(Icons.info_outline_rounded),
            applicationName: 'Desengastando',
            applicationLegalese:
                'Controle de gastos pessoal, simples e offline.\n'
                'Licença MIT.',
            child: Text('Sobre o Desengastando'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
