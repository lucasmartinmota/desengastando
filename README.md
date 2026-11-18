# Desengastando 😮‍💨

Controle de gastos pessoal, simples e **offline**, feito em Flutter para Android e iOS.
Seus dados ficam só no seu aparelho.

## Status

🚧 Em desenvolvimento (v0.1). Roadmap:

- [x] **Etapa 0** — Setup: estrutura, tema, navegação, lints
- [x] **Etapa 1** — Banco (Drift) e domínio: transações, categorias, orçamentos
- [ ] **Etapa 2** — Lançamentos: cadastro rápido e listagem
- [ ] **Etapa 3** — Resumo do mês com gráficos
- [ ] **Etapa 4** — Gerenciar categorias
- [ ] **Etapa 5** — Orçamentos por categoria com alertas
- [ ] **Etapa 6** — Polimento, ícone, backup/exportação

## Stack

| | |
|---|---|
| Estado | [Riverpod](https://riverpod.dev) + `riverpod_generator` |
| Banco local | [Drift](https://drift.simonbinder.eu) (SQLite) |
| Navegação | [go_router](https://pub.dev/packages/go_router) |
| Gráficos | [fl_chart](https://pub.dev/packages/fl_chart) |
| Lints | [very_good_analysis](https://pub.dev/packages/very_good_analysis) |

## Estrutura

```
lib/
├── app/        # MaterialApp, tema, rotas, shell de navegação
├── core/       # formatadores, widgets e utilitários compartilhados
├── data/       # banco de dados (Drift)
└── features/   # uma pasta por funcionalidade: data / domain / presentation
```

## Convenções

- **Dinheiro é `int` em centavos.** Nunca `double`. Conversão só na exibição (`CurrencyFormatter`).
- Arquivos `*.g.dart` são gerados e versionados; regenere após mudar providers ou tabelas.

## Rodando

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Testes e análise:

```bash
flutter analyze
flutter test
```

## Licença

Código sob [MIT](LICENSE). Fonte [Manrope](https://github.com/googlefonts/manrope) sob [SIL OFL 1.1](assets/fonts/manrope/OFL.txt).
