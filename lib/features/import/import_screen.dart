/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 */

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../services/apkg_service.dart';
import '../../services/database_service.dart';
import '../../models/card.dart';
import '../../models/note.dart';
import '../../models/deck.dart';
import '../../utils/date_utils.dart' as app_date_utils;

/// Tela para importar arquivos .apkg
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ApkgService _apkgService = ApkgService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isImporting = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _importApkg() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Selecionar arquivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apkg'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final file = result.files.single;

      // 2. Importar .apkg
      // Na web, usar bytes; no mobile, usar path
      ApkgImportResult importResult;
      if (kIsWeb) {
        // Na web, path não está disponível, usar bytes
        if (file.bytes == null) {
          throw Exception('Não foi possível ler o arquivo. Tente novamente.');
        }
        importResult = await _apkgService.importApkgFromBytes(file.bytes!);
      } else {
        // No mobile, usar path
        if (file.path == null) {
          throw Exception('Caminho do arquivo não disponível.');
        }
        importResult = await _apkgService.importApkg(file.path!);
      }

      // 3. Criar deck padrão ou usar existente
      final deckName = 'Deck Importado ${DateTime.now().toString().substring(0, 10)}';
      final deckId = await _databaseService.createDeck(deckName);

      // 4. Converter e salvar notas
      final noteMap = <int, String>{}; // Mapeia anki note ID -> novo note ID
      int noteCounter = 0;
      for (final ankiNote in importResult.notes) {
        final noteId = '${DateTime.now().millisecondsSinceEpoch}_${noteCounter++}';
        noteMap[ankiNote.id] = noteId;
        
        final note = Note(
          id: noteId,
          deckId: deckId,
          userId: '', // Não usado offline
          fields: ankiNote.fields,
          tags: ankiNote.tags,
          modelName: 'Basic',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ankiGuid: ankiNote.guid,
          ankiNoteId: ankiNote.id,
        );
        
        await _databaseService.saveNote(note);
      }

      // 5. Converter e salvar cards
      int cardsSaved = 0;
      int cardCounter = 0;
      for (final ankiCard in importResult.cards) {
        // Pular cards órfãos (sem note correspondente)
        if (!noteMap.containsKey(ankiCard.noteId)) continue;

        final cardId = '${DateTime.now().millisecondsSinceEpoch}_${cardCounter++}';
        final noteId = noteMap[ankiCard.noteId]!;
        
        // Converter queue do Anki para CardQueueType
        // Anki queue: 0=NEW, 1=LEARNING, 2=REVIEW, 3=DAY_LEARNING, -1=SUSPENDED, -2=SIBLING_BURIED, -3=MANUAL_BURIED
        CardQueueType queueType;
        if (ankiCard.queue == 0) {
          queueType = CardQueueType.newCard;
        } else if (ankiCard.queue == 1 || ankiCard.queue == 3) {
          queueType = CardQueueType.learning;
        } else if (ankiCard.queue == 2) {
          queueType = CardQueueType.review;
        } else if (ankiCard.queue < 0) {
          // Cards suspensos ou enterrados - tratamos como new
          queueType = CardQueueType.newCard;
        } else {
          queueType = CardQueueType.relearning;
        }

        // Converter due date
        final dueDate = app_date_utils.DateUtils.ankiTimestampToDateTime(ankiCard.due);
        
        final card = Card(
          id: cardId,
          noteId: noteId,
          deckId: deckId,
          userId: '', // Não usado offline
          queueType: queueType,
          fsrsDifficulty: 0.3,
          fsrsStability: ankiCard.interval > 0 ? ankiCard.interval.toDouble() : 0.0,
          fsrsRetrievability: 1.0,
          dueDate: dueDate,
          intervalDays: ankiCard.interval,
          easeFactor: ankiCard.easeFactor,
          reviewsCount: ankiCard.reviewsCount,
          lapsesCount: ankiCard.lapsesCount,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ankiCardId: ankiCard.id,
          ankiDue: ankiCard.due,
        );
        
        await _databaseService.saveCard(card);
        cardsSaved++;
      }
      
      setState(() {
        _successMessage =
            'Importado com sucesso!\n${importResult.notes.length} notas\n$cardsSaved cards\nDeck: $deckName';
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao importar: $e';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Deck'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 80,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Importar arquivo .apkg',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione um arquivo .apkg do Anki para importar seus flashcards',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importApkg,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(_isImporting ? 'Importando...' : 'Selecionar arquivo .apkg'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

