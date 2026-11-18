# Desengastando 😮‍💨

Controle de gastos pessoal, simples e **offline**, feito em Flutter para Android e iOS.
Seus dados ficam só no seu aparelho.

## Status

v0.1 — pronto para uso pessoal. Roadmap concluído:

- [x] **Etapa 0** — Setup: estrutura, tema, navegação, lints
- [x] **Etapa 1** — Banco (Drift) e domínio: transações, categorias, orçamentos
- [x] **Etapa 2** — Lançamentos: cadastro rápido e listagem
- [x] **Etapa 3** — Resumo do mês com gráficos
- [x] **Etapa 4** — Gerenciar categorias
- [x] **Etapa 5** — Orçamentos por categoria com alertas
- [x] **Etapa 6** — Polimento, ícone, backup/exportação

## Funcionalidades

- **Lançamentos** rápidos (valor já focado, "Hoje" pré-selecionado), com edição, exclusão por gesto e desfazer
- **Resumo do mês**: saldo, comparação com o mês anterior, gastos por categoria e evolução de 6 meses
- **Categorias** personalizáveis (cor, ícone, ordem), arquivadas sem perder o histórico
- **Lançamentos fixos** (salário, aluguel, assinaturas): cadastre uma vez e os próximos 12 meses já aparecem lançados, como previstos
- **Compras parceladas**: informe o total (ou o valor da parcela) e a quantidade, e cada parcela entra no seu mês ("Parcela 3/10")
- **Orçamentos** mensais por categoria, com aviso a partir de 80% e ao estourar
- **Backup** completo em JSON (exportar/restaurar) e **planilha CSV** dos lançamentos

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
- **Mudou o banco?** Suba `schemaVersion`, escreva o passo em `onUpgrade` e rode
  `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/` e
  `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`;
  `test/data/migration_test.dart` valida a migração contra os schemas antigos.

## Rodando

```bash
flutter pub get
dart run build_runner build
flutter run
```

Testes e análise:

```bash
flutter analyze
flutter test
```

## Ícone e tela de abertura

Os PNGs em `assets/icon/` são desenhados por código, em
`tool/icon/render_icons_test.dart`. Para mudar o ícone, edite esse arquivo e rode:

```bash
flutter test tool/icon/render_icons_test.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

> O `flutter_launcher_icons` altera `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
> no `project.pbxproj` do iOS por engano; descarte essa mudança.

## Gerando o instalável

**Android** (um APK por arquitetura, ~20 MB cada; celulares atuais usam `arm64-v8a`):

```bash
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

O build de release ainda usa a chave de debug — serve para instalar no próprio
celular. Para publicar na Play Store, crie uma chave de upload e configure o
`signingConfig` em `android/app/build.gradle.kts`.

**iOS**: abra `ios/Runner.xcworkspace` no Xcode, escolha seu time em
*Signing & Capabilities* e rode no aparelho (`flutter run --release`).

## Licença

Código sob [MIT](LICENSE). Fonte [Manrope](https://github.com/googlefonts/manrope) sob [SIL OFL 1.1](assets/fonts/manrope/OFL.txt).
