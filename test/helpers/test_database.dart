import 'package:desengastando/data/database/app_database.dart';
import 'package:drift/native.dart';

/// Banco SQLite em memória, novo a cada chamada (já com o seed padrão).
AppDatabase createTestDatabase() => AppDatabase(NativeDatabase.memory());
