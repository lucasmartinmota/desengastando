import 'package:desengastando/data/database/app_database.dart';

/// Valida o nome de uma categoria contra as já existentes do mesmo tipo
/// (incluindo arquivadas). Retorna a mensagem de erro ou `null` se ok.
///
/// A comparação ignora maiúsculas e espaços nas pontas: "mercado " e
/// "Mercado" seriam confusos lado a lado na lista.
String? validateCategoryName(
  String name,
  Iterable<TransactionCategory> existing, {
  int? exceptId,
}) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return 'Dê um nome à categoria';
  if (normalized.length > 40) return 'Use até 40 caracteres';
  final clash = existing.where(
    (c) => c.id != exceptId && c.name.trim().toLowerCase() == normalized,
  );
  if (clash.isEmpty) return null;
  return clash.first.archived
      ? 'Já existe uma categoria arquivada com esse nome'
      : 'Já existe uma categoria com esse nome';
}
