import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desengastando/data/database/database_provider.dart';
import 'package:desengastando/features/backup/data/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

/// Entrada e saída de arquivos do backup (folha de compartilhar e seletor
/// de arquivos do sistema). Separado para poder ser trocado nos testes.
class BackupFiles {
  const BackupFiles();

  /// Grava [content] num arquivo temporário e abre a folha de compartilhar,
  /// de onde dá para salvar no Drive, em Arquivos, mandar por e-mail etc.
  Future<void> share({
    required String fileName,
    required String content,
    required String mimeType,
    Rect? origin,
  }) => shareBytes(
    fileName: fileName,
    bytes: utf8.encode(content),
    mimeType: mimeType,
    origin: origin,
  );

  /// Igual a [share], mas para arquivos binários (ex.: PDF).
  Future<void> shareBytes({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    Rect? origin,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
        // Obrigatório no iPad: de onde o popover sai.
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Abre o seletor e devolve o conteúdo do arquivo, ou `null` se cancelar.
  Future<String?> pickText() async {
    // `any` em vez de filtrar por .json: no Android vários provedores não
    // reconhecem o MIME de JSON e o arquivo nem apareceria. O conteúdo é
    // validado depois.
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => const BackupFiles());
