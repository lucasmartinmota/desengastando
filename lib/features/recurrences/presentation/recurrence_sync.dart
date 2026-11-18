import 'dart:async';

import 'package:desengastando/features/recurrences/data/recurrences_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gera os lançamentos fixos que venceram: ao abrir o app e sempre que ele
/// volta para a frente (ex.: aberto em segundo plano desde ontem).
class RecurrenceSync extends ConsumerStatefulWidget {
  const RecurrenceSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RecurrenceSync> createState() => _RecurrenceSyncState();
}

class _RecurrenceSyncState extends ConsumerState<RecurrenceSync> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _generate);
    _generate();
  }

  void _generate() {
    // Falha aqui não deve derrubar o app; tenta de novo na próxima volta.
    unawaited(
      ref.read(recurrencesDaoProvider).generateDue().catchError((_) => 0),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
