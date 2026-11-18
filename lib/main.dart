import 'package:desengastando/app/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  // A Manrope vai embutida no app; a OFL pede que a licença acompanhe.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/manrope/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
  });
  runApp(const ProviderScope(child: DesengastandoApp()));
}
