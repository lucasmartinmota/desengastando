import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/data/transactions_dao.dart';
import 'package:flutter/material.dart';

/// Exclui o lançamento e oferece "Desfazer" (reinsere com o mesmo id).
///
/// Recebe o [messenger] já resolvido: quem chama costuma fechar a tela logo
/// em seguida, e o `context` deixa de ser válido.
Future<void> deleteTransactionWithUndo({
  required ScaffoldMessengerState messenger,
  required TransactionsDao dao,
  required Transaction transaction,
  VoidCallback? onUndone,
}) async {
  await dao.deleteTransaction(transaction.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Lançamento excluído'),
        behavior: SnackBarBehavior.floating,
        // Com action, o Flutter mantém a SnackBar até ser fechada;
        // queremos que ela suma sozinha.
        persist: false,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await dao.restoreTransaction(transaction);
            onUndone?.call();
          },
        ),
      ),
    );
}
