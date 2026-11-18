import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamentos')),
      body: const EmptyState(
        emoji: '🧾',
        title: 'Nenhum gasto registrado',
        message: 'Respira fundo, tá tudo bem.',
      ),
    );
  }
}
