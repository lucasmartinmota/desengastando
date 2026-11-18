import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Executado pelo flutter_test antes de cada arquivo de teste.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await testMain();
}
