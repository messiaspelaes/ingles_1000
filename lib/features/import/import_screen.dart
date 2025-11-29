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

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/apkg_service.dart';
import '../../services/supabase_service.dart';
import '../../models/card.dart';
import '../../models/note.dart';

/// Tela para importar arquivos .apkg
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ApkgService _apkgService = ApkgService();
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

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final apkgPath = result.files.single.path!;

      // 2. Importar .apkg
      final importResult = await _apkgService.importApkg(apkgPath);

      // 3. Salvar no Supabase
      // TODO: Implementar salvamento no Supabase
      // Por enquanto, apenas mostra sucesso
      
      setState(() {
        _successMessage =
            'Importado com sucesso!\n${importResult.notes.length} notas\n${importResult.cards.length} cards';
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

