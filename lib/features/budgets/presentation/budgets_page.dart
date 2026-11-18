import 'package:desengastando/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: const EmptyState(
        emoji: '🐷',
        title: 'Sem orçamentos definidos',
        message:
            'Defina limites por categoria e a gente avisa antes de apertar.',
      ),
    );
  }
}
