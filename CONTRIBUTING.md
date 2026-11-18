# Guia de desenvolvimento

App em Flutter para Android e iOS. Todos os dados ficam no aparelho.

## Stack

| | |
|---|---|
| Estado | [Riverpod](https://riverpod.dev) + `riverpod_generator` |
| Banco local | [Drift](https://drift.simonbinder.eu) (SQLite) |
| Navegação | [go_router](https://pub.dev/packages/go_router) |
| Gráficos | [fl_chart](https://pub.dev/packages/fl_chart) |
| Lints | [very_good_analysis](https://pub.dev/packages/very_good_analysis) |

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

## Estrutura

```
lib/
├── app/        # MaterialApp, tema, rotas, shell de navegação
├── core/       # formatadores, widgets e utilitários compartilhados
├── data/       # banco de dados (Drift)
└── features/   # uma pasta por funcionalidade: data / domain / presentation
```

## Convenções

- **Dinheiro é sempre `int` em centavos, nunca `double`.** A conversão para reais acontece só na exibição (`CurrencyFormatter`).
- Os arquivos `*.g.dart` são gerados e vão para o repositório. Gere de novo depois de mudar providers ou tabelas.
- **Mudou o banco?**
  1. Aumente o `schemaVersion` e escreva o passo em `onUpgrade`.
  2. Rode
     `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`.
  3. Rode
     `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`.

  O teste `test/data/migration_test.dart` valida a migração contra os schemas antigos.

## Ícone e tela de abertura

Os PNGs em `assets/icon/` são desenhados por código, no arquivo
`tool/icon/render_icons_test.dart`. Para mudar o ícone, edite esse arquivo e rode:

```bash
flutter test tool/icon/render_icons_test.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

> O `flutter_launcher_icons` altera por engano a configuração
> `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` no `project.pbxproj`
> do iOS. Descarte essa mudança.

## Gerando o instalável

**Android:** gera um APK por arquitetura, de uns 20 MB cada. Os celulares atuais usam `arm64-v8a`.

```bash
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Para atualizar um aparelho conectado sem perder os dados, use
`adb install -r <apk>`. Evite o `flutter install`: ele desinstala o app e apaga os dados.

O build de release ainda é assinado com a chave de debug. Para publicar na Play
Store, crie uma chave de upload e configure o `signingConfig` em
`android/app/build.gradle.kts`.

**iOS:** abra `ios/Runner.xcworkspace` no Xcode, escolha seu time em
*Signing & Capabilities* e rode no aparelho com `flutter run --release`.
